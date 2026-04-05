import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge


# ============================================================
# Helpers
# ============================================================

def get_uo_out_fields(dut):
    v = int(dut.uo_out.value)
    done = v & 1
    fail = (v >> 1) & 1
    passed = (v >> 2) & 1
    ram_en = (v >> 3) & 1
    ecc_bypass = (v >> 4) & 1
    sb_err = (v >> 5) & 1
    db_err = (v >> 6) & 1
    sb_fix = (v >> 7) & 1
    return done, fail, passed, ram_en, ecc_bypass, sb_err, db_err, sb_fix


def rtl_internal_available(dut):
    return hasattr(dut, "tb_ecc_fi_en")


async def reset_dut(dut, cycles=10):
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0

    if hasattr(dut, "tb_mbist_fi_en"):
        dut.tb_mbist_fi_en.value = 0
        dut.tb_mbist_fi_addr.value = 0
        dut.tb_mbist_fi_data.value = 0

    if hasattr(dut, "tb_ecc_fi_en"):
        dut.tb_ecc_fi_en.value = 0
        dut.tb_ecc_fi_data.value = 0

    if hasattr(dut, "tb_ecc_enc_en"):
        dut.tb_ecc_enc_en.value = 0
        dut.tb_ecc_enc_data_in.value = 0

    await ClockCycles(dut.clk, cycles)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)


# ============================================================
# Test 1: MBIST Functional (RTL + GLS)
# ============================================================

@cocotb.test()
async def test_mbist_func(dut):
    dut._log.info("=== MBIST Functional ===")

    clock = Clock(dut.clk, 10, unit="ns")
    cocotb.start_soon(clock.start())

    await reset_dut(dut)

    dut.ui_in.value = 1

    await RisingEdge(dut.clk)

    for i in range(1000):
        done, fail, passed, ram_en, ecc_bypass, sb_err, db_err, sb_fix = get_uo_out_fields(dut)

        if done == 0 and i > 1:
            assert ecc_bypass == 1, f"ecc_bypass failed at cycle {i}"

        if passed == 1 or fail == 1:
            break

        await RisingEdge(dut.clk)
    else:
        assert False, "MBIST timeout"

    await ClockCycles(dut.clk, 5)

    done, fail, passed, ram_en, ecc_bypass, sb_err, db_err, sb_fix = get_uo_out_fields(dut)

    assert ecc_bypass == 0, "ecc_bypass should return low"
    assert fail == 0, "MBIST fail unexpected"
    assert passed == 1, "MBIST pass missing"

    dut._log.info(f"MBIST done={done} fail={fail} pass={passed}")


# ============================================================
# Test 2: MBIST Fault Injection (RTL only)
# ============================================================

@cocotb.test()
async def test_mbist_fault_injection(dut):
    if not rtl_internal_available(dut):
        dut._log.info("Skipping MBIST fault injection in GLS")
        return

    dut._log.info("=== MBIST Fault Injection ===")

    clock = Clock(dut.clk, 10, unit="ns")
    cocotb.start_soon(clock.start())

    fault_tests = [
        ("SAF", 0, 0x0000000020),
        ("TF",  1, 0xFFFFFFFFFB),
        ("AF",  2, 0xAAAAAAAAAA),
        ("CF",  0, 0x0000000001),
    ]

    fail_count = 0

    for test_name, fault_addr, fault_data in fault_tests:
        dut._log.info(f"Running {test_name}")

        await reset_dut(dut)

        dut.ui_in.value = 1

        for _ in range(200):
            await RisingEdge(dut.clk)
            check = int(dut.tb_mbist_check_pipe.value)
            if check & 1:
                break

        dut.tb_ecc_fi_data.value = fault_data
        dut.tb_ecc_fi_en.value = 1
        await ClockCycles(dut.clk, 3)
        dut.tb_ecc_fi_en.value = 0

        for _ in range(800):
            done, fail, passed, *_ = get_uo_out_fields(dut)
            if passed or fail:
                break
            await RisingEdge(dut.clk)

        await ClockCycles(dut.clk, 2)

        done, fail, passed, *_ = get_uo_out_fields(dut)

        if fail != 1:
            fail_count += 1

    assert fail_count == 0, f"{fail_count} MBIST fault tests failed"


# ============================================================
# Test 3: ECC Functional (RTL only)
# ============================================================

@cocotb.test()
async def test_ecc_func(dut):
    if not rtl_internal_available(dut):
        dut._log.info("Skipping ECC functional test in GLS")
        return

    dut._log.info("=== ECC Functional ===")

    clock = Clock(dut.clk, 10, unit="ns")
    cocotb.start_soon(clock.start())

    await reset_dut(dut)

    patterns = [0xA5A5A5A5, 0x3C3C3C3C, 0xF0F0F0F0, 0x55555555]

    for pattern in patterns:
        dut.tb_ecc_enc_en.value = 1
        dut.tb_ecc_enc_data_in.value = pattern
        await ClockCycles(dut.clk, 1)

        encoded = int(dut.tb_ecc_encoded_data.value)

        dut.tb_ecc_fi_en.value = 1
        dut.tb_ecc_fi_data.value = encoded
        await ClockCycles(dut.clk, 1)

        decoded = int(dut.tb_ecc_decoded_data.value)
        _, _, _, _, _, sb_err, db_err, _ = get_uo_out_fields(dut)

        assert decoded == pattern
        assert sb_err == 0
        assert db_err == 0


# ============================================================
# Test 4: ECC Fault Injection (RTL only)
# ============================================================

@cocotb.test()
async def test_ecc_fault_injection(dut):
    if not rtl_internal_available(dut):
        dut._log.info("Skipping ECC fault injection in GLS")
        return

    dut._log.info("=== ECC Fault Injection ===")

    clock = Clock(dut.clk, 10, unit="ns")
    cocotb.start_soon(clock.start())

    await reset_dut(dut)

    data = 0xA5A5A5A5

    dut.tb_ecc_enc_en.value = 1
    dut.tb_ecc_enc_data_in.value = data
    await ClockCycles(dut.clk, 1)

    encoded = int(dut.tb_ecc_encoded_data.value)

    # Single bit error
    faulty_sb = encoded ^ (1 << 1)

    dut.tb_ecc_fi_en.value = 1
    dut.tb_ecc_fi_data.value = faulty_sb
    await ClockCycles(dut.clk, 1)

    decoded = int(dut.tb_ecc_decoded_data.value)
    _, _, _, _, _, sb_err, db_err, _ = get_uo_out_fields(dut)

    assert decoded == data
    assert sb_err == 1
    assert db_err == 0

    # Double bit error
    faulty_db = encoded ^ 0b11

    dut.tb_ecc_fi_data.value = faulty_db
    await ClockCycles(dut.clk, 1)

    _, _, _, _, _, sb_err, db_err, _ = get_uo_out_fields(dut)

    assert db_err == 1