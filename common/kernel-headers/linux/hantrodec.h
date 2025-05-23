/*
 * This file is auto-generated. Modifications will be lost.
 *
 * See https://android.googlesource.com/platform/bionic/+/master/libc/kernel/
 * for more information.
 */
#ifndef _UAPI_HANTRODEC_H_
#define _UAPI_HANTRODEC_H_
#include <linux/ioctl.h>
#include <linux/types.h>
#undef PDEBUG
#ifdef HANTRODEC_DEBUG
#define PDEBUG(fmt,args...) fprintf(stderr, fmt, ##args)
#else
#define PDEBUG(fmt,args...)
#endif
struct core_desc {
  __u32 id;
  __u32 * regs;
  __u32 size;
};
#define HANTRODEC_IOC_MAGIC 'k'
#define HANTRODEC_PP_INSTANCE _IO(HANTRODEC_IOC_MAGIC, 1)
#define HANTRODEC_HW_PERFORMANCE _IO(HANTRODEC_IOC_MAGIC, 2)
#define HANTRODEC_IOCGHWOFFSET _IOR(HANTRODEC_IOC_MAGIC, 3, __u32 *)
#define HANTRODEC_IOCGHWIOSIZE _IOR(HANTRODEC_IOC_MAGIC, 4, __u32 *)
#define HANTRODEC_IOC_CLI _IO(HANTRODEC_IOC_MAGIC, 5)
#define HANTRODEC_IOC_STI _IO(HANTRODEC_IOC_MAGIC, 6)
#define HANTRODEC_IOC_MC_OFFSETS _IOR(HANTRODEC_IOC_MAGIC, 7, __u64 *)
#define HANTRODEC_IOC_MC_CORES _IOR(HANTRODEC_IOC_MAGIC, 8, __u32 *)
#define HANTRODEC_IOCS_DEC_PUSH_REG _IOW(HANTRODEC_IOC_MAGIC, 9, struct core_desc *)
#define HANTRODEC_IOCS_PP_PUSH_REG _IOW(HANTRODEC_IOC_MAGIC, 10, struct core_desc *)
#define HANTRODEC_IOCH_DEC_RESERVE _IO(HANTRODEC_IOC_MAGIC, 11)
#define HANTRODEC_IOCT_DEC_RELEASE _IO(HANTRODEC_IOC_MAGIC, 12)
#define HANTRODEC_IOCQ_PP_RESERVE _IO(HANTRODEC_IOC_MAGIC, 13)
#define HANTRODEC_IOCT_PP_RELEASE _IO(HANTRODEC_IOC_MAGIC, 14)
#define HANTRODEC_IOCX_DEC_WAIT _IOWR(HANTRODEC_IOC_MAGIC, 15, struct core_desc *)
#define HANTRODEC_IOCX_PP_WAIT _IOWR(HANTRODEC_IOC_MAGIC, 16, struct core_desc *)
#define HANTRODEC_IOCS_DEC_PULL_REG _IOWR(HANTRODEC_IOC_MAGIC, 17, struct core_desc *)
#define HANTRODEC_IOCS_PP_PULL_REG _IOWR(HANTRODEC_IOC_MAGIC, 18, struct core_desc *)
#define HANTRODEC_IOCG_CORE_WAIT _IOR(HANTRODEC_IOC_MAGIC, 19, __u32 *)
#define HANTRODEC_IOX_ASIC_ID _IOWR(HANTRODEC_IOC_MAGIC, 20, __u32 *)
#define HANTRODEC_IOCG_CORE_ID _IO(HANTRODEC_IOC_MAGIC, 21)
#define HANTRODEC_DEBUG_STATUS _IO(HANTRODEC_IOC_MAGIC, 29)
#define HANTRODEC_IOC_MAXNR 29
#endif
