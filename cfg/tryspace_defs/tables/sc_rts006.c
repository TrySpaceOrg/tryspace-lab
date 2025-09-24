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
#include "lc_msg.h"
#include "lc_msgdefs.h"
#include "lc_msgids.h"
#include "radio_msg.h"
#include "radio_msgids.h"

/* Note: Assumes SC_PLATFORM_ENABLE_HEADER_UPDATE is true */

/* Custom table structure, modify as needed to add desired commands */
typedef struct
{
    /* 1 - Set Radio Mode - Duplex */
    SC_RtsEntryHeader_t hdr1;
    RADIO_Config_cmd_t  cmd1;

    /* 2 - Set Radio Mode - Rx Only */
    SC_RtsEntryHeader_t hdr2;
    RADIO_Config_cmd_t cmd2;

} SC_RtsStruct006_t;

/* Define the union to size the table correctly */
typedef union
{
    SC_RtsStruct006_t rts;
    uint16            buf[SC_RTS_BUFF_SIZE];
} SC_RtsTable006_t;

/* Helper macro to get size of structure elements */
#define SC_MEMBER_SIZE(member) (sizeof(((SC_RtsStruct006_t *)0)->member))

/* Used designated initializers to be verbose, modify as needed/desired */
SC_RtsTable006_t SC_Rts006 = 
{
    /* 1 - Set Radio Mode - Duplex */
    .rts.hdr1.WakeupCount = 1,
    .rts.cmd1.CmdHeader = CFE_MSG_CMD_HDR_INIT(RADIO_CMD_MID, SC_MEMBER_SIZE(cmd1), RADIO_CONFIG_CC, 0x00),
    .rts.cmd1.DeviceCfg.Mode = RADIO_MODE_DUPLEX,
    .rts.cmd1.DeviceCfg.RxSpeedSetting = 1,
    .rts.cmd1.DeviceCfg.RxWavelengthSetting = 2,
    .rts.cmd1.DeviceCfg.TxSpeedSetting = 3,
    .rts.cmd1.DeviceCfg.TxWavelengthSetting = 4,

    /* 2 - Set Radio Mode - Rx Only */
    .rts.hdr2.WakeupCount = 480, /* 8 minutes */
    .rts.cmd2.CmdHeader = CFE_MSG_CMD_HDR_INIT(RADIO_CMD_MID, SC_MEMBER_SIZE(cmd2), RADIO_CONFIG_CC, 0x00),
    .rts.cmd2.DeviceCfg.Mode = RADIO_MODE_RX,
    .rts.cmd2.DeviceCfg.RxSpeedSetting = 1,
    .rts.cmd2.DeviceCfg.RxWavelengthSetting = 2,
    .rts.cmd2.DeviceCfg.TxSpeedSetting = 0,
    .rts.cmd2.DeviceCfg.TxWavelengthSetting = 0,
};

/* Macro for table structure */
CFE_TBL_FILEDEF(SC_Rts006, SC.RTS_TBL006, Start Pass RTS_TBL006, sc_rts006.tbl)
