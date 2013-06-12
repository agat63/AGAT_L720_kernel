/*
 * Author: Paul Reioux aka Faux123 <reioux@gmail.com>
 *
 * krait-defines
 * Copyright 2013 Paul Reioux
 *
 * This software is licensed under the terms of the GNU General Public
 * License version 2, as published by the Free Software Foundation, and
 * may be copied, distributed, and modified under those terms.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 */
#ifdef CONFIG_CPU_OVERCLOCK
#ifdef CONFIG_OC_ULTIMATE
#define OVERCLOCK_EXTRA_FREQS	7
#else
#define OVERCLOCK_EXTRA_FREQS	4
#endif // OC Ultimate
#else
#define OVERCLOCK_EXTRA_FREQS	0
#endif // OC

#ifdef CONFIG_LOW_CPUCLOCKS
#define FREQ_TABLE_SIZE		(42 + OVERCLOCK_EXTRA_FREQS)
#else
#define FREQ_TABLE_SIZE		(38 + OVERCLOCK_EXTRA_FREQS)
#endif
