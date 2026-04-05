import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge

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

async def reset_dut(dut, cycles=10):
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    
    dut.tb_mbist_fi_en.value = 0
    dut.tb_mbist_fi_addr.value = 0
    dut.tb_mbist_fi_data.value = 0
    dut.tb_ecc_fi_en.value = 0
    dut.tb_ecc_fi_data.value = 0
    dut.tb_ecc_enc_en.value = 0
    dut.tb_ecc_enc_data_in.value = 0
    
    await ClockCycles(dut.clk, cycles)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)

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
            assert ecc_bypass == 1
            
        if passed == 1 or fail == 1:
            break
            
        await RisingEdge(dut.clk)
    else:
        assert False

    await ClockCycles(dut.clk, 5)
    
    done, fail, passed, ram_en, ecc_bypass, sb_err, db_err, sb_fix = get_uo_out_fields(dut)
    
    assert ecc_bypass == 0
    
    dut._log.info(f"Results: done={done} fail={fail} pass={passed}")
    assert fail == 0
    assert passed == 1

@cocotb.test()
async def test_mbist_fault_injection(dut):
    dut._log.info("=== MBIST Fault Injection ===")
    clock = Clock(dut.clk, 10, unit="ns")
    cocotb.start_soon(clock.start())
    
    fault_tests = [
        ("SAF", 0, 0x0000000020),
        ("TF",  1, 0xFFFFFFFFFB),
        ("AF",  2, 0xAAAAAAAAAA), 
        ("CF",  0, 0x0000000001),
    ]

    pass_count = 0
    fail_count = 0

    for test_name, fault_addr, fault_data in fault_tests:
        dut._log.info(f"Running {test_name} fault at {fault_addr}: 0x{fault_data:010X}")
        await reset_dut(dut)
        
        dut.ui_in.value = 1
        
        for i in range(200):
            await RisingEdge(dut.clk)
            try:
                check = int(dut.tb_mbist_check_pipe.value)
            except ValueError:
                check = 0
            if check & 1:
                break
                
        dut.tb_ecc_fi_data.value = fault_data
        dut.tb_ecc_fi_en.value = 1
        await ClockCycles(dut.clk, 3)
        dut.tb_ecc_fi_en.value = 0
        
        for i in range(800):
            done, fail, passed, ram_en, ecc_bypass, sb_err, db_err, sb_fix = get_uo_out_fields(dut)
            if passed == 1 or fail == 1:
                break
            await RisingEdge(dut.clk)
        else:
            assert False
            
        await ClockCycles(dut.clk, 2)
        done, fail, passed, ram_en, ecc_bypass, sb_err, db_err, sb_fix = get_uo_out_fields(dut)
        
        if fail == 1:
            pass_count += 1
        else:
            fail_count += 1

    dut._log.info("======================================")
    dut._log.info(f"MBIST FAULT INJECTION: PASS={pass_count} FAIL={fail_count}")
    dut._log.info("======================================")
    assert fail_count == 0

@cocotb.test()
async def test_ecc_func(dut):
    dut._log.info("=== ECC Functional ===")
    clock = Clock(dut.clk, 10, unit="ns")
    cocotb.start_soon(clock.start())
    await reset_dut(dut)
    
    test_patterns = [0xA5A5A5A5, 0x3C3C3C3C, 0xF0F0F0F0, 0x55555555]
    
    for pattern in test_patterns:
        dut.tb_ecc_enc_en.value = 1
        dut.tb_ecc_enc_data_in.value = pattern
        await ClockCycles(dut.clk, 1)
        
        encoded_val = int(dut.tb_ecc_encoded_data.value)
        
        dut.tb_ecc_fi_en.value = 1
        dut.tb_ecc_fi_data.value = encoded_val
        await ClockCycles(dut.clk, 1)
        
        done, fail, passed, ram_en, ecc_bypass, sb_err, db_err, sb_fix = get_uo_out_fields(dut)
        decoded_val = int(dut.tb_ecc_decoded_data.value)
        
        if decoded_val != pattern or sb_err != 0 or db_err != 0:
            assert False

@cocotb.test()
async def test_ecc_fault_injection(dut):
    dut._log.info("=== ECC Fault Injection ===")
    clock = Clock(dut.clk, 10, unit="ns")
    cocotb.start_soon(clock.start())
    await reset_dut(dut)
    
    data = 0xA5A5A5A5
    dut.tb_ecc_enc_en.value = 1
    dut.tb_ecc_enc_data_in.value = data
    await ClockCycles(dut.clk, 1)
    
    enc_out = int(dut.tb_ecc_encoded_data.value)
    
    dut._log.info("--- Single-bit error ---")
    faulty_sb = enc_out ^ (1 << 1)
    dut.tb_ecc_fi_en.value = 1
    dut.tb_ecc_fi_data.value = faulty_sb
    await ClockCycles(dut.clk, 1)
    
    done, fail, passed, ram_en, ecc_bypass, sb_err, db_err, sb_fix = get_uo_out_fields(dut)
    decoded_val = int(dut.tb_ecc_decoded_data.value)
    
    assert decoded_val == data
    assert sb_err == 1
    assert db_err == 0
    
    dut._log.info("--- Double-bit error ---")
    faulty_db = enc_out ^ 0b11
    dut.tb_ecc_fi_en.value = 1
    dut.tb_ecc_fi_data.value = faulty_db
    await ClockCycles(dut.clk, 1)
    
    done, fail, passed, ram_en, ecc_bypass, sb_err, db_err, sb_fix = get_uo_out_fields(dut)
    
    assert db_err == 1
