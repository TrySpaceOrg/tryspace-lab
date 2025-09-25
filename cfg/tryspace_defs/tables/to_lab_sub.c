/************************************************************************
 * NASA Docket No. GSC-18,719-1, and identified as “core Flight System: Bootes”
 *
 * Copyright (c) 2020 United States Government as represented by the
 * Administrator of the National Aeronautics and Space Administration.
 * All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License. You may obtain
 * a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 ************************************************************************/

/**
 * \file
 *  Define TO Lab CPU specific subscription table
 */

#include "cfe_tbl_filedef.h" /* Required to obtain the CFE_TBL_FILEDEF macro definition */
#include "cfe_sb_api_typedefs.h"
#include "to_lab_tbl.h"
#include "cfe_msgids.h"

/* cFS */
#include "ci_lab_msgids.h"
#include "cf_msgids.h"
#include "ds_msgids.h"
#include "fm_msgids.h"
#include "lc_msgids.h"
#include "sc_msgids.h"
#include "sch_msgids.h"
#include "to_lab_msgids.h"

/* Components */
#include "adcs_msgids.h"
#include "demo_msgids.h"
#include "eps_msgids.h"
#include "radio_msgids.h"

TO_LAB_Subs_t TO_LAB_Subs = {.Subs = {
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
    {CFE_SB_MSGID_WRAP_VALUE(CF_HK_TLM_MID), {0,0}, 4},
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
    {CFE_SB_MSGID_WRAP_VALUE(ADCS_HK_TLM_MID), {0, 0}, 32},
    {CFE_SB_MSGID_WRAP_VALUE(DEMO_HK_TLM_MID), {0, 0}, 4},
    {CFE_SB_MSGID_WRAP_VALUE(DEMO_DEVICE_TLM_MID), {0, 0}, 4},
    {CFE_SB_MSGID_WRAP_VALUE(EPS_HK_TLM_MID), {0, 0}, 4},
    {CFE_SB_MSGID_WRAP_VALUE(EPS_DEVICE_TLM_MID), {0, 0}, 4},
    {CFE_SB_MSGID_WRAP_VALUE(RADIO_HK_TLM_MID), {0, 0}, 4},

    /* CFE_SB_MSGID_RESERVED entry to mark the end of valid MsgIds */
    {CFE_SB_MSGID_RESERVED, {0, 0}, 0}}};

CFE_TBL_FILEDEF(TO_LAB_Subs, TO_LAB_APP.TO_LAB_Subs, TO Lab Sub Tbl, to_lab_sub.tbl)
