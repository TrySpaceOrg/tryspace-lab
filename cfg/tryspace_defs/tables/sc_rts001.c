/************************************************************************
 * NASA Docket No. GSC-18,924-1, and identified as “Core Flight
 * System (cFS) Stored Command Application version 3.1.1”
 *
 * Copyright (c) 2021 United States Government as represented by the
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
 * @file
 *   CFS Stored Command (SC) sample RTS table 1
 *
 * The following source code demonstrates how to create a sample
 * Stored Command RTS table using the software defined command structures.
 * It's also possible to create this table via alternative tools
 * (ground system) and or system agnostic data definitions (XTCE/EDS/JSON).
 *
 * This source file creates a sample RTS table that contains only
 * the following commands that are scheduled as follows:
 *
 * SC NOOP command, execution wakeup count relative to start of RTS = 0
 * SC Enable RTS #2 command, execution wakeup count relative to prev cmd = 5
 * SC Start RTS #2 command, execution wakeup count relative to prev cmd = 5
 */

#include "cfe.h"
#include "cfe_tbl_filedef.h"

#include "sc_tbldefs.h"      /* defines SC table headers */
#include "sc_platform_cfg.h" /* defines table buffer size */
#include "sc_msgdefs.h"      /* defines SC command code values */
#include "sc_msgids.h"       /* defines SC packet msg ID's */
#include "sc_msg.h"          /* defines SC message structures */

/* Specific includes */
#include "ds_msg.h"
#include "ds_msgdefs.h"
#include "ds_msgids.h"
#include "lc_msg.h"
#include "lc_msgdefs.h"
#include "lc_msgids.h"
#include "sc_msg.h"
#include "sc_msgdefs.h"
#include "sc_msgids.h"
#include "to_lab_msgids.h"
#include "to_lab_msg.h"

/* Note: Assumes SC_PLATFORM_ENABLE_HEADER_UPDATE is true */

/* Custom table structure, modify as needed to add desired commands */
typedef struct
{
    /* 1 - Enable DS */
    SC_RtsEntryHeader_t hdr1;
    DS_AppStateCmd_t cmd1;
    /* 2 - Enable Debug */
    SC_RtsEntryHeader_t hdr2;
    TO_LAB_EnableOutputCmd_t cmd2;
    /* 3 - Enable LC */
    SC_RtsEntryHeader_t hdr3;
    LC_SetLCStateCmd_t cmd3;
    /* 4 - Enable RTS Group */
    SC_RtsEntryHeader_t hdr4;
    SC_EnableRtsGrpCmd_t cmd4;
    /* 5 - Start RTS #3 () */
    SC_RtsEntryHeader_t hdr5;
    SC_StartRtsCmd_t cmd5;

} SC_RtsStruct001_t;

/* Define the union to size the table correctly */
typedef union
{
    SC_RtsStruct001_t rts;
    uint16            buf[SC_RTS_BUFF_SIZE];
} SC_RtsTable001_t;

/* Helper macro to get size of structure elements */
#define SC_MEMBER_SIZE(member) (sizeof(((SC_RtsStruct001_t *)0)->member))

/* Used designated initializers to be verbose, modify as needed/desired */
SC_RtsTable001_t SC_Rts001 = 
{
    /* 1 - Enable DS */
    .rts.hdr1.WakeupCount = 5,
    .rts.cmd1.CommandHeader = CFE_MSG_CMD_HDR_INIT(DS_CMD_MID, SC_MEMBER_SIZE(cmd1), DS_SET_APP_STATE_CC, 0x00),
    .rts.cmd1.Payload.EnableState = 0x0001,
    .rts.cmd1.Payload.Padding = 0x0000,

    /* 2 - Enable Debug */
    .rts.hdr2.WakeupCount = 1,
    .rts.cmd2.CommandHeader = CFE_MSG_CMD_HDR_INIT(TO_LAB_CMD_MID, SC_MEMBER_SIZE(cmd2), TO_LAB_OUTPUT_ENABLE_CC, 0x00),
    .rts.cmd2.Payload.dest_IP = "tryspace-gsw",

    /* 3 - Enable LC */
    .rts.hdr3.WakeupCount = 1,
    .rts.cmd3.CommandHeader = CFE_MSG_CMD_HDR_INIT(LC_CMD_MID, SC_MEMBER_SIZE(cmd3), LC_SET_LC_STATE_CC, 0x00),
    .rts.cmd3.Payload.NewLCState = LC_STATE_ACTIVE,
    .rts.cmd3.Payload.Padding = 0x0000,

    /* 4 - Enable RTS Group */
    .rts.hdr4.WakeupCount = 1,
    .rts.cmd4.CommandHeader = CFE_MSG_CMD_HDR_INIT(SC_CMD_MID, SC_MEMBER_SIZE(cmd4), SC_ENABLE_RTS_GRP_CC, 0x00),
    .rts.cmd4.Payload.FirstRtsNum = 0x0001,
    .rts.cmd4.Payload.LastRtsNum = 0x0008,

    /* 5 - Start RTS #3 (Initialization) */
    .rts.hdr5.WakeupCount = 1,
    .rts.cmd5.CommandHeader = CFE_MSG_CMD_HDR_INIT(SC_CMD_MID, SC_MEMBER_SIZE(cmd5), SC_START_RTS_CC, 0x00),
    .rts.cmd5.Payload.RtsNum = 0x0003,
    .rts.cmd5.Payload.Padding = 0x0000,
};

/* Macro for table structure */
CFE_TBL_FILEDEF(SC_Rts001, SC.RTS_TBL001, SC Example RTS_TBL001, sc_rts001.tbl)
