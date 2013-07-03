/*
 * Copyright (c) 2011-2013, The Linux Foundation. All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 and
 * only version 2 as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 */

#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/platform_device.h>
#include <mach/rpm-regulator.h>
#include <mach/msm_bus_board.h>
#include <mach/msm_bus.h>

#include "mach/socinfo.h"
#include "acpuclock.h"
#include "acpuclock-krait.h"

static struct hfpll_data hfpll_data __initdata = {
	.mode_offset = 0x00,
	.l_offset = 0x08,
	.m_offset = 0x0C,
	.n_offset = 0x10,
	.config_offset = 0x04,
	.config_val = 0x7845C665,
	.has_droop_ctl = true,
	.droop_offset = 0x14,
	.droop_val = 0x0108C000,
	.low_vdd_l_max = 22,
	.nom_vdd_l_max = 42,
	.vdd[HFPLL_VDD_NONE] =       0,
	.vdd[HFPLL_VDD_LOW]  =  945000,
	.vdd[HFPLL_VDD_NOM]  = 1050000,
	.vdd[HFPLL_VDD_HIGH] = 1250000,
};

static struct scalable scalable[] __initdata = {
	[CPU0] = {
		.hfpll_phys_base = 0x00903200,
		.aux_clk_sel_phys = 0x02088014,
		.aux_clk_sel = 3,
		.sec_clk_sel = 2,
		.l2cpmr_iaddr = 0x4501,
		.vreg[VREG_CORE] = { "krait0", 1450000 },
		.vreg[VREG_MEM]  = { "krait0_mem", 1250000 },
		.vreg[VREG_DIG]  = { "krait0_dig", 1250000 },
		.vreg[VREG_HFPLL_A] = { "krait0_hfpll", 1800000 },
	},
	[CPU1] = {
		.hfpll_phys_base = 0x00903240,
		.aux_clk_sel_phys = 0x02098014,
		.aux_clk_sel = 3,
		.sec_clk_sel = 2,
		.l2cpmr_iaddr = 0x5501,
		.vreg[VREG_CORE] = { "krait1", 1450000 },
		.vreg[VREG_MEM]  = { "krait1_mem", 1250000 },
		.vreg[VREG_DIG]  = { "krait1_dig", 1250000 },
		.vreg[VREG_HFPLL_A] = { "krait1_hfpll", 1800000 },
	},
	[CPU2] = {
		.hfpll_phys_base = 0x00903280,
		.aux_clk_sel_phys = 0x020A8014,
		.aux_clk_sel = 3,
		.sec_clk_sel = 2,
		.l2cpmr_iaddr = 0x6501,
		.vreg[VREG_CORE] = { "krait2", 1450000 },
		.vreg[VREG_MEM]  = { "krait2_mem", 1250000 },
		.vreg[VREG_DIG]  = { "krait2_dig", 1250000 },
		.vreg[VREG_HFPLL_A] = { "krait2_hfpll", 1800000 },
	},
	[CPU3] = {
		.hfpll_phys_base = 0x009032C0,
		.aux_clk_sel_phys = 0x020B8014,
		.aux_clk_sel = 3,
		.sec_clk_sel = 2,
		.l2cpmr_iaddr = 0x7501,
		.vreg[VREG_CORE] = { "krait3", 1450000 },
		.vreg[VREG_MEM]  = { "krait3_mem", 1250000 },
		.vreg[VREG_DIG]  = { "krait3_dig", 1250000 },
		.vreg[VREG_HFPLL_A] = { "krait3_hfpll", 1800000 },
	},
	[L2] = {
		.hfpll_phys_base = 0x00903300,
		.aux_clk_sel_phys = 0x02011028,
		.aux_clk_sel = 3,
		.sec_clk_sel = 2,
		.l2cpmr_iaddr = 0x0500,
		.vreg[VREG_HFPLL_A] = { "l2_hfpll", 1800000 },
	},
};

/*
 * The correct maximum rate for 8064ab in 600 MHZ.
 * We rely on the RPM rounding requests up here.
*/
static struct msm_bus_paths bw_level_tbl[] __initdata = {
	[0] =  BW_MBPS(640), /* At least  80 MHz on bus. */
	[1] = BW_MBPS(1064), /* At least 133 MHz on bus. */
	[2] = BW_MBPS(1600), /* At least 200 MHz on bus. */
	[3] = BW_MBPS(2128), /* At least 266 MHz on bus. */
	[4] = BW_MBPS(3200), /* At least 400 MHz on bus. */
	[5] = BW_MBPS(4264), /* At least 533 MHz on bus. */
	// [6] = BW_MBPS(4600), /* At least 600 MHz on bus. */
};

static struct msm_bus_scale_pdata bus_scale_data __initdata = {
	.usecase = bw_level_tbl,
	.num_usecases = ARRAY_SIZE(bw_level_tbl),
	.active_only = 1,
	.name = "acpuclk-8064",
};

static struct l2_level l2_freq_tbl[] __initdata = {
	[0]  = { {  378000, HFPLL, 2, 0x1C },  950000, 1050000, 1 },
	[1]  = { {  384000, PLL_8, 0, 0x00 },  950000, 1050000, 1 },
	[2]  = { {  432000, HFPLL, 2, 0x20 }, 1050000, 1050000, 2 },
	[3]  = { {  486000, HFPLL, 2, 0x24 }, 1050000, 1050000, 2 },
	[4]  = { {  540000, HFPLL, 2, 0x28 }, 1050000, 1050000, 2 },
	[5]  = { {  594000, HFPLL, 1, 0x16 }, 1050000, 1050000, 2 },
	[6]  = { {  648000, HFPLL, 1, 0x18 }, 1050000, 1050000, 4 },
	[7]  = { {  702000, HFPLL, 1, 0x1A }, 1050000, 1050000, 4 },
	[8]  = { {  756000, HFPLL, 1, 0x1C }, 1150000, 1150000, 4 },
	[9]  = { {  810000, HFPLL, 1, 0x1E }, 1150000, 1150000, 4 },
	[10] = { {  864000, HFPLL, 1, 0x20 }, 1150000, 1150000, 4 },
	[11] = { {  918000, HFPLL, 1, 0x22 }, 1150000, 1150000, 5 },
	[12] = { {  972000, HFPLL, 1, 0x24 }, 1150000, 1150000, 5 },
	[13] = { { 1026000, HFPLL, 1, 0x26 }, 1150000, 1150000, 5 },
	[14] = { { 1080000, HFPLL, 1, 0x28 }, 1150000, 1150000, 5 },
	[15] = { { 1134000, HFPLL, 1, 0x2A }, 1150000, 1150000, 5 },
	[16] = { { 1188000, HFPLL, 1, 0x2C }, 1150000, 1150000, 5 },
	[17] = { { 1242000, HFPLL, 1, 0x2E }, 1250000, 1250000, 5 },
	[18] = { { 1296000, HFPLL, 1, 0x30 }, 1250000, 1250000, 5 },
	{ }
};

static struct acpu_level tbl_PVS2_2000MHz[] __initdata = {
	{ 1, {   162000, HFPLL, 2, 0x0C }, L2(0),   850000 },
	{ 1, {   216000, HFPLL, 2, 0x10 }, L2(0),   850000 },
	{ 1, {   270000, HFPLL, 2, 0x14 }, L2(0),   850000 },
	{ 1, {   324000, HFPLL, 2, 0x18 }, L2(0),   875000 },
	{ 1, {   378000, HFPLL, 2, 0x1C }, L2(0),   875000 },
	{ 1, {   384000, PLL_8, 0, 0x00 }, L2(1),   900000 },
	{ 1, {   486000, HFPLL, 2, 0x24 }, L2(5),   900000 },
	{ 1, {   594000, HFPLL, 1, 0x16 }, L2(5),   900000 },
	{ 1, {   702000, HFPLL, 1, 0x1A }, L2(5),   900000 },
	{ 1, {   810000, HFPLL, 1, 0x1E }, L2(5),   912500 },
	{ 1, {   918000, HFPLL, 1, 0x22 }, L2(5),   925000 },
	{ 1, {  1026000, HFPLL, 1, 0x26 }, L2(5),   950000 },
	{ 1, {  1134000, HFPLL, 1, 0x2A }, L2(15),  975000 },
	{ 1, {  1242000, HFPLL, 1, 0x2E }, L2(15),  987500 },
	{ 1, {  1350000, HFPLL, 1, 0x32 }, L2(15), 1012500 },
	{ 1, {  1458000, HFPLL, 1, 0x36 }, L2(15), 1050000 },
	{ 1, {  1566000, HFPLL, 1, 0x3A }, L2(15), 1075000 },
	{ 1, {  1674000, HFPLL, 1, 0x3E }, L2(15), 1112500 },
	{ 1, {  1782000, HFPLL, 1, 0x42 }, L2(15), 1162500 },
	{ 1, {  1836000, HFPLL, 1, 0x44 }, L2(15), 1187500 },
	{ 1, {  1890000, HFPLL, 1, 0x46 }, L2(15), 1212500 },
#ifdef CONFIG_CPU_OVERCLOCK
	{ 1, {  1944000, HFPLL, 1, 0x48 }, L2(15), 1237500 },
	{ 1, {  1998000, HFPLL, 1, 0x4A }, L2(16), 1262500 },
	{ 1, {  2052000, HFPLL, 1, 0x4C }, L2(16), 1287500 },
	{ 1, {  2106000, HFPLL, 1, 0x4E }, L2(16), 1312500 },
#ifdef CONFIG_OC_ULTIMATE
	{ 1, {  2160000, HFPLL, 1, 0x50 }, L2(16), 1337500 },
	{ 1, {  2214000, HFPLL, 1, 0x52 }, L2(17), 1362500 },
	{ 1, {  2268000, HFPLL, 1, 0x54 }, L2(17), 1387500 },
#endif // OC Ultimate
#endif // OC
	{ 0, { 0 } }
};
static struct pvs_table pvs_tables[NUM_SPEED_BINS][NUM_PVS] __initdata = {
	[2][2] = { tbl_PVS2_2000MHz, sizeof(tbl_PVS2_2000MHz),     0 },
};

static struct acpuclk_krait_params acpuclk_8064_params __initdata = {
	.scalable = scalable,
	.scalable_size = sizeof(scalable),
	.hfpll_data = &hfpll_data,
	.pvs_tables = pvs_tables,
	.l2_freq_tbl = l2_freq_tbl,
	.l2_freq_tbl_size = sizeof(l2_freq_tbl),
	.bus_scale = &bus_scale_data,
	.pte_efuse_phys = 0x007000C0,
	.stby_khz = 378000,
};

static int __init acpuclk_8064_probe(struct platform_device *pdev)
{
	if (cpu_is_apq8064ab() ||
		SOCINFO_VERSION_MAJOR(socinfo_get_version()) == 2) {
		acpuclk_8064_params.hfpll_data->low_vdd_l_max = 37;
		acpuclk_8064_params.hfpll_data->nom_vdd_l_max = 74;
	}

	return acpuclk_krait_init(&pdev->dev, &acpuclk_8064_params);
}

static struct platform_driver acpuclk_8064_driver = {
	.driver = {
		.name = "acpuclk-8064",
		.owner = THIS_MODULE,
	},
};

static int __init acpuclk_8064_init(void)
{
	return platform_driver_probe(&acpuclk_8064_driver,
				     acpuclk_8064_probe);
}
device_initcall(acpuclk_8064_init);
