module notepadpp

pub const wm_user = 1024
pub const nppmsg = wm_user + 1000

pub const nppm_getcurrentscintilla = nppmsg + 4
pub const nppm_getcurrentlangtype = nppmsg + 5
pub const nppm_setcurrentlangtype = nppmsg + 6

pub const nppm_getnbopenfiles = nppmsg + 7
pub const all_open_files = 0
pub const primary_view = 1
pub const second_view = 2

pub const nppm_getopenfilenames = nppmsg + 8
pub const nppm_modelessdialog = nppmsg + 12
pub const modelessdialogadd = 0
pub const modelessdialogremove = 1

pub const nppm_getnbsessionfiles = nppmsg + 13
pub const nppm_getsessionfiles = nppmsg + 14
pub const nppm_savesession = nppmsg + 15
pub const nppm_savecurrentsession = nppmsg + 16
pub const nppm_getopenfilenamesprimary = nppmsg + 17
pub const nppm_getopenfilenamessecond = nppmsg + 18
pub const nppm_createscintillahandle = nppmsg + 20
pub const nppm_destroyscintillahandle = nppmsg + 21
pub const nppm_getnbuserlang = nppmsg + 22
pub const nppm_getcurrentdocindex = nppmsg + 23
pub const main_view = 0
pub const sub_view = 1

pub const nppm_setstatusbar = nppmsg + 24
pub const statusbar_doc_type = 0
pub const statusbar_doc_size = 1
pub const statusbar_cur_pos = 2
pub const statusbar_eof_format = 3
pub const statusbar_unicode_type = 4
pub const statusbar_typing_mode = 5

pub const nppm_getmenuhandle = nppmsg + 25
pub const npppluginmenu = 0
pub const nppmainmenu = 1
pub const nppm_encodesci = nppmsg + 26
pub const nppm_decodesci = nppmsg + 27
pub const nppm_activatedoc = nppmsg + 28
pub const nppm_launchfindinfilesdlg = nppmsg + 29
pub const nppm_dmmshow = nppmsg + 30
pub const nppm_dmmhide = nppmsg + 31
pub const nppm_dmmupdatedispinfo = nppmsg + 32
pub const nppm_dmmregasdckdlg = nppmsg + 33
pub const nppm_loadsession = nppmsg + 34
pub const nppm_dmmviewothertab = nppmsg + 35
pub const nppm_reloadfile = nppmsg + 36
pub const nppm_switchtofile = nppmsg + 37
pub const nppm_savecurrentfile = nppmsg + 38
pub const nppm_saveallfiles = nppmsg + 39
pub const nppm_setmenuitemcheck = nppmsg + 40
pub const nppm_addtoolbaricon = nppmsg + 41
pub const nppm_getwindowsversion = nppmsg + 42
pub const nppm_dmmgetpluginhwndbyname = nppmsg + 43
pub const nppm_makecurrentbufferdirty = nppmsg + 44
pub const nppm_getenablethemetexturefunc = nppmsg + 45
pub const nppm_getpluginsconfigdir = nppmsg + 46
pub const nppm_msgtoplugin = nppmsg + 47
pub const nppm_menucommand = nppmsg + 48
pub const nppm_triggertabbarcontextmenu = nppmsg + 49
pub const nppm_getnppversion = nppmsg + 50
pub const nppm_hidetabbar = nppmsg + 51
pub const nppm_istabbarhidden = nppmsg + 52
pub const nppm_getposfrombufferid = nppmsg + 57
pub const nppm_getfullpathfrombufferid = nppmsg + 58
pub const nppm_getbufferidfrompos = nppmsg + 59
pub const nppm_getcurrentbufferid = nppmsg + 60
pub const nppm_reloadbufferid = nppmsg + 61
pub const nppm_getbufferlangtype = nppmsg + 64
pub const nppm_setbufferlangtype = nppmsg + 65
pub const nppm_getbufferencoding = nppmsg + 66
pub const nppm_setbufferencoding = nppmsg + 67
pub const nppm_getbufferformat = nppmsg + 68
pub const nppm_setbufferformat = nppmsg + 69
pub const nppm_hidetoolbar = nppmsg + 70
pub const nppm_istoolbarhidden = nppmsg + 71
pub const nppm_hidemenu = nppmsg + 72
pub const nppm_ismenuhidden = nppmsg + 73
pub const nppm_hidestatusbar = nppmsg + 74
pub const nppm_isstatusbarhidden = nppmsg + 75
pub const nppm_getshortcutbycmdid = nppmsg + 76
pub const nppm_doopen = nppmsg + 77
pub const nppm_savecurrentfileas = nppmsg + 78
pub const nppm_getcurrentnativelangencoding = nppmsg + 79
pub const nppm_allocatesupported = nppmsg + 80
pub const nppm_allocatecmdid = nppmsg + 81
pub const nppm_allocatemarker = nppmsg + 82
pub const nppm_getlanguagename = nppmsg + 83
pub const nppm_getlanguagedesc = nppmsg + 84
pub const nppm_showdocswitcher = nppmsg + 85
pub const nppm_isdocswitchershown = nppmsg + 86
pub const nppm_getappdatapluginsallowed = nppmsg + 87
pub const nppm_getcurrentview = nppmsg + 88
pub const nppm_docswitcherdisablecolumn = nppmsg + 89
pub const nppm_geteditordefaultforegroundcolor = nppmsg + 90
pub const nppm_geteditordefaultbackgroundcolor = nppmsg + 91
pub const nppm_setsmoothfont = nppmsg + 92
pub const nppm_seteditorborderedge = nppmsg + 93
pub const nppm_savefile = nppmsg + 94
pub const nppm_disableautoupdate = nppmsg + 95
pub const nppm_removeshortcutbycmdid = nppmsg + 96
pub const nppm_getpluginhomepath = nppmsg + 97
pub const nppm_getsettingsoncloudpath = nppmsg + 98

pub const var_not_recognized = 0
pub const full_current_path = 1
pub const current_directory = 2
pub const file_name = 3
pub const name_part = 4
pub const ext_part = 5
pub const current_word = 6
pub const npp_directory = 7
pub const current_line = 8
pub const current_column = 9
pub const npp_full_file_path = 10
pub const getfilenameatcursor = 11

pub const runcommand_user = wm_user + 3000
pub const nppm_getfullcurrentpath = runcommand_user + full_current_path
pub const nppm_getcurrentdirectory = runcommand_user + current_directory
pub const nppm_getfilename = runcommand_user + file_name
pub const nppm_getnamepart = runcommand_user + name_part
pub const nppm_getextpart = runcommand_user + ext_part
pub const nppm_getcurrentword = runcommand_user + current_word
pub const nppm_getnppdirectory = runcommand_user + npp_directory
pub const nppm_getfilenameatcursor = runcommand_user + getfilenameatcursor
pub const nppm_getcurrentline = runcommand_user + current_line
pub const nppm_getcurrentcolumn = runcommand_user + current_column
pub const nppm_getnppfullfilepath = runcommand_user + npp_full_file_path

// Notification code
pub const nppn_first = 1000
pub const nppn_ready = nppn_first + 1
pub const nppn_tbmodification = nppn_first + 2
pub const nppn_filebeforeclose = nppn_first + 3
pub const nppn_fileopened = nppn_first + 4
pub const nppn_fileclosed = nppn_first + 5
pub const nppn_filebeforeopen = nppn_first + 6
pub const nppn_filebeforesave = nppn_first + 7
pub const nppn_filesaved = nppn_first + 8
pub const nppn_shutdown = nppn_first + 9
pub const nppn_bufferactivated = nppn_first + 10
pub const nppn_langchanged = nppn_first + 11
pub const nppn_wordstylesupdated = nppn_first + 12
pub const nppn_shortcutremapped = nppn_first + 13
pub const nppn_filebeforeload = nppn_first + 14
pub const nppn_fileloadfailed = nppn_first + 15
pub const nppn_readonlychanged = nppn_first + 16

pub const docstatus_readonly = 1
pub const docstatus_bufferdirty = 2

pub const nppn_docorderchanged = nppn_first + 17
pub const nppn_snapshotdirtyfileloaded = nppn_first + 18
pub const nppn_beforeshutdown = nppn_first + 19
pub const nppn_cancelshutdown = nppn_first + 20
pub const nppn_filebeforerename = nppn_first + 21
pub const nppn_filerenamecancel = nppn_first + 22
pub const nppn_filerenamed = nppn_first + 23
pub const nppn_filebeforedelete = nppn_first + 24
pub const nppn_filedeletefailed = nppn_first + 25
pub const nppn_filedeleted = nppn_first + 26

// docking dialog related
//   defines for docking manager
pub const cont_left = 0
pub const cont_right = 1
pub const cont_top = 2
pub const cont_bottom = 3
pub const dockcont_max = 4

// mask params for plugins of internal dialogs
pub const dws_icontab = 0x00000001 // icon for tabs are available

pub const dws_iconbar = 0x00000002 // icon for icon bar are available (currently not supported)

pub const dws_addinfo = 0x00000004 // additional information are in use

pub const dws_paramsall = (dws_icontab | dws_iconbar | dws_addinfo)

// default docking values for first call of plugin
pub const dws_df_cont_left = (cont_left << 28) // default docking on left

pub const dws_df_cont_right = (cont_right << 28) // default docking on right

pub const dws_df_cont_top = (cont_top << 28) // default docking on top

pub const dws_df_cont_bottom = (cont_bottom << 28) // default docking on bottom

pub const dws_df_floating = u32(0x80000000) // default state is floating
