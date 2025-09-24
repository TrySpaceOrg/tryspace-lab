/************************************************************************
 * Radio Downlink Subscription Table
 ************************************************************************/

#include "cfe_tbl_filedef.h" /* Required to obtain the CFE_TBL_FILEDEF macro definition */
#include "cfe_sb_api_typedefs.h"
#include "cfe_msgids.h"
#include "radio_sub_tbl.h"

/* cFS */
#include "cf_msgids.h"
#include "ds_msgids.h"
#include "fm_msgids.h"
#include "lc_msgids.h"
#include "sc_msgids.h"
#include "sch_msgids.h"

/* Components */
#include "adcs_msgids.h"
#include "demo_msgids.h"
#include "eps_msgids.h"
#include "radio_msgids.h"

/* Local Structures */
#define CF_CONFIG_TLM_MID 0x08B2
#define CF_PDU_TLM_MID    0x0FFD

RADIO_Subs_t RADIO_Subs = {.Subs = {
    /* cFE Core */
    {CFE_SB_MSGID_WRAP_VALUE(CFE_ES_HK_TLM_MID), {0, 0}, 4},
    {CFE_SB_MSGID_WRAP_VALUE(CFE_EVS_HK_TLM_MID), {0, 0}, 4},
    {CFE_SB_MSGID_WRAP_VALUE(CFE_SB_HK_TLM_MID), {0, 0}, 4},
    {CFE_SB_MSGID_WRAP_VALUE(CFE_TBL_HK_TLM_MID), {0, 0}, 4},
    {CFE_SB_MSGID_WRAP_VALUE(CFE_TIME_HK_TLM_MID), {0, 0}, 4},
    {CFE_SB_MSGID_WRAP_VALUE(CFE_TIME_DIAG_TLM_MID), {0, 0}, 4},
    {CFE_SB_MSGID_WRAP_VALUE(CFE_SB_STATS_TLM_MID), {0, 0}, 4},
    {CFE_SB_MSGID_WRAP_VALUE(CFE_TBL_REG_TLM_MID), {0, 0}, 4},
    {CFE_SB_MSGID_WRAP_VALUE(CFE_EVS_LONG_EVENT_MSG_MID), {0, 0}, 32},
    {CFE_SB_MSGID_WRAP_VALUE(CFE_EVS_SHORT_EVENT_MSG_MID), {0, 0}, 32},
    {CFE_SB_MSGID_WRAP_VALUE(CFE_ES_APP_TLM_MID), {0, 0}, 4},
    {CFE_SB_MSGID_WRAP_VALUE(CFE_ES_MEMSTATS_TLM_MID), {0, 0}, 4},

    /* cFS */
    {CFE_SB_MSGID_WRAP_VALUE(CF_CONFIG_TLM_MID), {0,0}, 4},
    {CFE_SB_MSGID_WRAP_VALUE(CF_HK_TLM_MID), {0,0}, 4},
    {CFE_SB_MSGID_WRAP_VALUE(CF_PDU_TLM_MID), {0,0}, 32},
    {CFE_SB_MSGID_WRAP_VALUE(DS_HK_TLM_MID), {0,0}, 4},
    {CFE_SB_MSGID_WRAP_VALUE(FM_HK_TLM_MID), {0,0}, 4},
    {CFE_SB_MSGID_WRAP_VALUE(FM_FILE_INFO_TLM_MID), {0,0}, 4},
    {CFE_SB_MSGID_WRAP_VALUE(FM_DIR_LIST_TLM_MID), {0,0}, 4},
    {CFE_SB_MSGID_WRAP_VALUE(FM_OPEN_FILES_TLM_MID), {0,0}, 4},
    {CFE_SB_MSGID_WRAP_VALUE(FM_FREE_SPACE_TLM_MID), {0,0}, 4},
    {CFE_SB_MSGID_WRAP_VALUE(LC_HK_TLM_MID), {0,0}, 4},
    {CFE_SB_MSGID_WRAP_VALUE(SC_HK_TLM_MID), {0,0}, 4},
    {CFE_SB_MSGID_WRAP_VALUE(SCH_HK_TLM_MID), {0,0}, 4},

    /* Components */
    {CFE_SB_MSGID_WRAP_VALUE(ADCS_HK_TLM_MID), {0, 0}, 4},
    {CFE_SB_MSGID_WRAP_VALUE(DEMO_HK_TLM_MID), {0, 0}, 4},
    {CFE_SB_MSGID_WRAP_VALUE(DEMO_DEVICE_TLM_MID), {0, 0}, 4},
    {CFE_SB_MSGID_WRAP_VALUE(EPS_HK_TLM_MID), {0, 0}, 4},
    {CFE_SB_MSGID_WRAP_VALUE(EPS_DEVICE_TLM_MID), {0, 0}, 4},
    {CFE_SB_MSGID_WRAP_VALUE(RADIO_HK_TLM_MID), {0, 0}, 4},

    /* CFE_SB_MSGID_RESERVED entry to mark the end of valid MsgIds */
    {CFE_SB_MSGID_RESERVED, {0, 0}, 0}
}};

CFE_TBL_FILEDEF(RADIO_Subs, RADIO_APP.RADIO_Subs, Radio Downlink Sub Tbl, radio_sub.tbl)
