.386
.model flat, stdcall
option casemap :none

include   windows.inc
include   user32.inc
includelib  user32.lib
include   kernel32.inc
includelib  kernel32.lib
include   comdlg32.inc
includelib  comdlg32.lib

ICO_MAIN  equ 1000
IDA_MAIN  equ 2000
IDM_MAIN  equ 2000
IDM_NEW   equ 2101
IDM_OPEN  equ 2102
IDM_SAVE  equ 2103
IDM_SAVEAS equ  2104
IDM_EXIT  equ 2105
IDM_UNDO  equ 2201
IDM_REDO  equ 2202
IDM_SELALL  equ 2203
IDM_COPY  equ 2204
IDM_CUT   equ 2205
IDM_PASTE equ 2206
IDM_FIND  equ 2207
IDM_FINDPREV  equ 2208
IDM_FINDNEXT  equ 2209
IDM_Help  equ 3101
IDM_ABOUT  equ 3102

;«««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««
.data?
;«««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««

hInstance dd  ?
hWinMain  dd  ?
hMenu   dd  ?
hWinEdit  dd  ?
hFile   dd  ?
hFindDialog dd  ?
idFindMessage dd  ?
szFileName  db  MAX_PATH dup (?)
szFindText  db  100 dup (?)
;«««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««
.data
;«««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««

stFind    FINDREPLACE <sizeof FINDREPLACE,0,0,FR_DOWN,szFindText,\
    0,sizeof szFindText,0,0,0,0>
    .const
FINDMSGSTRING db  'commdlg_FindReplace',0
szClassName db  'NotePad',0
szCaptionMain db  'NotePad',0
szDllEdit db  'RichEd20.dll',0
szClassEdit db  'RichEdit20A',0
szNotFound  db  'String not found!',0
szFilter  db  'Text Files(*.txt)',0,'*.txt',0
    db  'All Files(*.*)',0,'*.*',0,0
szDefaultExt  db  'txt',0
szDefExt  db  'txt',0
szErrOpenFile db  'Unable to open file!',0
szErrCreateFile db  'Unable to create file!',0
szModify  db  'File is not saved,save it now?',0
szFont    db  '宋体',0
szCaption db  'question',0
szSaveCaption db  'Please enter the file name to save',0
szTitleFormat db  '%s - [NotePad]',0
szNoName  db  'untitled',0
szAboutName db  'About this procedure',0
;«««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««
.code
;«««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««

_ProcStream proc uses ebx edi esi _dwCookie,_lpBuffer,_dwBytes,_lpBytes
    .if _dwCookie
      invoke  ReadFile,hFile,_lpBuffer,_dwBytes,_lpBytes,0
    .else
      invoke  WriteFile,hFile,_lpBuffer,_dwBytes,_lpBytes,0
    .endif
    xor eax,eax
    ret
_ProcStream endp

_SaveFile proc
    local @stES:EDITSTREAM
    .if ! hFile
      call  _SaveAs
      .if ! eax
        ret
      .endif
    .endif
    invoke  SetFilePointer,hFile,0,0,FILE_BEGIN
    invoke  SetEndOfFile,hFile
    mov @stES.dwCookie,FALSE
    mov @stES.dwError,NULL
    mov @stES.pfnCallback,offset _ProcStream
    invoke  SendMessage,hWinEdit,EM_STREAMOUT,SF_TEXT,addr @stES
    invoke  SendMessage,hWinEdit,EM_SETMODIFY,FALSE,0
    mov eax,TRUE
    ret
_SaveFile endp

_SaveAs   proc
    local @stOF:OPENFILENAME
    local @stES:EDITSTREAM
    invoke  RtlZeroMemory,addr @stOF,sizeof @stOF

    mov @stOF.lStructSize,sizeof @stOF
    push  hWinMain
    pop @stOF.hwndOwner
    mov @stOF.lpstrFilter,offset szFilter
    mov @stOF.lpstrFile,offset szFileName
    mov @stOF.nMaxFile,MAX_PATH
    mov @stOF.Flags,OFN_PATHMUSTEXIST
    mov @stOF.lpstrDefExt,offset szDefExt
    mov @stOF.lpstrTitle,offset szSaveCaption
    invoke  GetSaveFileName,addr @stOF
    .if eax

      invoke  CreateFile,addr szFileName,GENERIC_READ or GENERIC_WRITE,\
        FILE_SHARE_READ,0,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,0
      .if eax !=  INVALID_HANDLE_VALUE
    push  eax
        .if hFile
          invoke  CloseHandle,hFile
        .endif
    pop eax

    mov hFile,eax
    call  _SaveFile
    call  _SetCaption
    call  _SetStatus
    mov eax,TRUE
    ret
      .else
        invoke  MessageBox,hWinMain,addr szErrCreateFile,NULL,MB_OK or MB_ICONERROR
      .endif
    .endif
    mov eax,FALSE
    ret
_SaveAs   endp

_OpenFile proc
    local @stOF:OPENFILENAME
    local @stES:EDITSTREAM

    invoke  RtlZeroMemory,addr @stOF,sizeof @stOF
    mov @stOF.lStructSize,sizeof @stOF
    push  hWinMain
    pop @stOF.hwndOwner
    mov @stOF.lpstrFilter,offset szFilter
    mov @stOF.lpstrFile,offset szFileName
    mov @stOF.nMaxFile,MAX_PATH
    mov @stOF.Flags,OFN_FILEMUSTEXIST or OFN_PATHMUSTEXIST
    mov @stOF.lpstrDefExt,offset szDefaultExt
    invoke  GetOpenFileName,addr @stOF
    .if eax

      invoke  CreateFile,addr szFileName,GENERIC_READ or GENERIC_WRITE,\
        FILE_SHARE_READ or FILE_SHARE_WRITE,0,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
      .if eax ==  INVALID_HANDLE_VALUE
        invoke  MessageBox,hWinMain,addr szErrOpenFile,NULL,MB_OK or MB_ICONSTOP
        ret
      .endif
      push  eax
      .if hFile
        invoke  CloseHandle,hFile
      .endif
      pop eax
      mov hFile,eax

      mov @stES.dwCookie,TRUE
      mov @stES.pfnCallback,offset _ProcStream
      invoke  SendMessage,hWinEdit,EM_STREAMIN,SF_TEXT,addr @stES
      invoke  SendMessage,hWinEdit,EM_SETMODIFY,FALSE,0
      call  _SetCaption
    .endif
    ret
_OpenFile endp

_CheckModify  proc
 
    invoke  SendMessage,hWinEdit,EM_GETMODIFY,0,0
    .if eax
      invoke  MessageBox,hWinMain,addr szModify,addr szCaption,\
        MB_YESNOCANCEL or MB_ICONQUESTION
      .if eax ==  IDYES
        call  _SaveFile
      .elseif eax ==  IDNO
        mov eax,TRUE
      .elseif eax ==  IDCANCEL
        xor eax,eax
      .endif
    .else
      mov eax,TRUE
    .endif
    ret
_CheckModify  endp


_FindText proc
    local @stFindText:FINDTEXTEX


    invoke  SendMessage,hWinEdit,EM_EXGETSEL,0,addr @stFindText.chrg
    .if stFind.Flags & FR_DOWN
      push  @stFindText.chrg.cpMax
      pop @stFindText.chrg.cpMin
    .endif
    mov @stFindText.chrg.cpMax,-1

    mov @stFindText.lpstrText,offset szFindText
    mov ecx,stFind.Flags
    and ecx,FR_MATCHCASE or FR_DOWN or FR_WHOLEWORD

    invoke  SendMessage,hWinEdit,EM_FINDTEXTEX,ecx,addr @stFindText
    .if eax ==  -1
      mov ecx,hWinMain
      .if hFindDialog
        mov ecx,hFindDialog
      .endif
      invoke  MessageBox,ecx,addr szNotFound,NULL,MB_OK or MB_ICONINFORMATION
      ret
    .endif
    invoke  SendMessage,hWinEdit,EM_EXSETSEL,0,addr @stFindText.chrgText
    invoke  SendMessage,hWinEdit,EM_SCROLLCARET,NULL,NULL
    ret
_FindText endp

_SetCaption proc
    local @szBuffer[1024]:byte
    .if szFileName
      mov eax,offset szFileName
    .else
      mov eax,offset szNoName
    .endif
    invoke  wsprintf,addr @szBuffer,addr szTitleFormat,eax
    invoke  SetWindowText,hWinMain,addr @szBuffer
    ret
_SetCaption endp


_ProcDlgAbout proc  uses ebx edi esi hWnd,wMsg,wParam,lParam
    mov eax,wMsg
    .if eax == WM_CLOSE
      invoke  EndDialog,hWnd,NULL
    .elseif eax == WM_INITDIALOG
      mov eax,TRUE
    .elseif eax == WM_COMMAND
      mov eax,wParam
      .if ax == IDOK
        invoke  EndDialog,hWnd,NULL
      .endif
    .else
      mov eax,FALSE
      ret
    .endif
    mov eax,TRUE
    ret
_ProcDlgAbout endp


_About proc 
    invoke  DialogBoxParam,hInstance,IDM_ABOUT,hWinMain,offset _ProcDlgAbout,NULL
    ret
_About endp
 

_SetStatus  proc
    local @stRange:CHARRANGE
    invoke  SendMessage,hWinEdit,EM_EXGETSEL,0,addr @stRange

    mov eax,@stRange.cpMin
    .if eax ==  @stRange.cpMax
      invoke  EnableMenuItem,hMenu,IDM_COPY,MF_GRAYED
      invoke  EnableMenuItem,hMenu,IDM_CUT,MF_GRAYED
    .else
      invoke  EnableMenuItem,hMenu,IDM_COPY,MF_ENABLED
      invoke  EnableMenuItem,hMenu,IDM_CUT,MF_ENABLED
    .endif

    invoke  SendMessage,hWinEdit,EM_CANPASTE,0,0
    .if eax
      invoke  EnableMenuItem,hMenu,IDM_PASTE,MF_ENABLED
    .else
      invoke  EnableMenuItem,hMenu,IDM_PASTE,MF_GRAYED
    .endif

    invoke  SendMessage,hWinEdit,EM_CANREDO,0,0
    .if eax
      invoke  EnableMenuItem,hMenu,IDM_REDO,MF_ENABLED
    .else
      invoke  EnableMenuItem,hMenu,IDM_REDO,MF_GRAYED
    .endif

    invoke  SendMessage,hWinEdit,EM_CANUNDO,0,0
    .if eax
      invoke  EnableMenuItem,hMenu,IDM_UNDO,MF_ENABLED
    .else
      invoke  EnableMenuItem,hMenu,IDM_UNDO,MF_GRAYED
    .endif

    invoke  GetWindowTextLength,hWinEdit
    .if eax
      invoke  EnableMenuItem,hMenu,IDM_SELALL,MF_ENABLED
    .else
      invoke  EnableMenuItem,hMenu,IDM_SELALL,MF_GRAYED
    .endif

    invoke  SendMessage,hWinEdit,EM_GETMODIFY,0,0
    .if eax
      invoke  EnableMenuItem,hMenu,IDM_SAVE,MF_ENABLED
    .else
      invoke  EnableMenuItem,hMenu,IDM_SAVE,MF_GRAYED
    .endif

    .if szFindText
      invoke  EnableMenuItem,hMenu,IDM_FINDNEXT,MF_ENABLED
      invoke  EnableMenuItem,hMenu,IDM_FINDPREV,MF_ENABLED
    .else
      invoke  EnableMenuItem,hMenu,IDM_FINDNEXT,MF_GRAYED
      invoke  EnableMenuItem,hMenu,IDM_FINDPREV,MF_GRAYED
    .endif

    ret
_SetStatus  endp

_Init   proc
    local @stCf:CHARFORMAT

    push  hWinMain
    pop stFind.hwndOwner
    invoke  RegisterWindowMessage,addr FINDMSGSTRING
    mov idFindMessage,eax


    invoke  CreateWindowEx,WS_EX_CLIENTEDGE,offset szClassEdit,NULL,\
      WS_CHILD OR WS_VISIBLE OR WS_VSCROLL OR WS_HSCROLL \
      OR ES_MULTILINE or ES_NOHIDESEL,\
      0,0,0,0,\
      hWinMain,0,hInstance,NULL
    mov hWinEdit,eax
    invoke  SendMessage,hWinEdit,EM_SETTEXTMODE,TM_PLAINTEXT,0
    invoke  RtlZeroMemory,addr @stCf,sizeof @stCf
    mov @stCf.cbSize,sizeof @stCf
    mov @stCf.yHeight,9 * 20
    mov @stCf.dwMask,CFM_FACE or CFM_SIZE or CFM_BOLD
    invoke  _SetCaption
    invoke  lstrcpy,addr @stCf.szFaceName,addr szFont
    invoke  SendMessage,hWinEdit,EM_SETCHARFORMAT,0,addr @stCf
    invoke  SendMessage,hWinEdit,EM_EXLIMITTEXT,0,-1
    ret
_Init   endp

_Quit   proc
    invoke  _CheckModify
    .if eax
      invoke  DestroyWindow,hWinMain
      invoke  PostQuitMessage,NULL
      .if hFile
        invoke  CloseHandle,hFile
      .endif
    .endif
    ret
_Quit   endp

_ProcWinMain  proc  uses ebx edi esi hWnd,uMsg,wParam,lParam
    local @stRange:CHARRANGE
    local @stRect:RECT
    mov eax,uMsg
    .if eax ==  WM_SIZE
      invoke  GetClientRect,hWinMain,addr @stRect
      invoke  MoveWindow,hWinEdit,0,0,@stRect.right,@stRect.bottom,TRUE


    .elseif eax ==  WM_COMMAND
      mov eax,wParam
      movzx eax,ax
      .if eax ==  IDM_NEW
        invoke  _CheckModify
        .if eax
          .if hFile
            invoke  CloseHandle,hFile
            mov hFile,0
          .endif
          mov szFileName,0
          invoke  SetWindowText,hWinEdit,NULL
          invoke  _SetCaption
          invoke  _SetStatus
        .endif
      .elseif eax ==  IDM_OPEN
        invoke  _CheckModify
        .if eax
          call  _OpenFile
        .endif
      .elseif eax ==  IDM_SAVE
        call  _SaveFile
      .elseif eax ==  IDM_SAVEAS
        call  _SaveAs
      .elseif eax ==  IDM_EXIT
        invoke  _Quit
      .elseif eax ==  IDM_UNDO
        invoke  SendMessage,hWinEdit,EM_UNDO,0,0
      .elseif eax ==  IDM_REDO
        invoke  SendMessage,hWinEdit,EM_REDO,0,0
      .elseif eax == IDM_ABOUT
        invoke  _About
      .elseif eax ==  IDM_SELALL
        mov @stRange.cpMin,0
        mov @stRange.cpMax,-1
        invoke  SendMessage,hWinEdit,EM_EXSETSEL,0,addr @stRange
      .elseif eax ==  IDM_COPY
        invoke  SendMessage,hWinEdit,WM_COPY,0,0
      .elseif eax ==  IDM_CUT
        invoke  SendMessage,hWinEdit,WM_CUT,0,0
      .elseif eax ==  IDM_PASTE
        invoke  SendMessage,hWinEdit,WM_PASTE,0,0
      .elseif eax ==  IDM_FIND
        and stFind.Flags,not FR_DIALOGTERM
        invoke  FindText,addr stFind
        .if eax
          mov hFindDialog,eax
        .endif
      .elseif eax ==  IDM_FINDPREV
        and stFind.Flags,not FR_DOWN
        invoke  _FindText
      .elseif eax ==  IDM_FINDNEXT
        or  stFind.Flags,FR_DOWN
        invoke  _FindText
      .endif

    .elseif eax ==  WM_INITMENU
      call  _SetStatus
    .elseif eax ==  idFindMessage
      .if stFind.Flags & FR_DIALOGTERM
        mov hFindDialog,0
      .else
        invoke  _FindText
      .endif

    .elseif eax ==  WM_ACTIVATE
      mov eax,wParam
      .if (ax ==  WA_CLICKACTIVE ) || (ax == WA_ACTIVE)
        invoke  SetFocus,hWinEdit
      .endif

    .elseif eax ==  WM_CREATE
      push  hWnd
      pop hWinMain
      invoke  _Init

    .elseif eax ==  WM_CLOSE
      call  _Quit

    .else
      invoke  DefWindowProc,hWnd,uMsg,wParam,lParam
      ret
    .endif

    xor eax,eax
    ret
_ProcWinMain  endp

_WinMain  proc
    local @stWndClass:WNDCLASSEX
    local @stMsg:MSG
    local @hAccelerator,@hRichEdit
    invoke  LoadLibrary,offset szDllEdit
    mov @hRichEdit,eax
    invoke  GetModuleHandle,NULL
    mov hInstance,eax
    invoke  LoadMenu,hInstance,IDM_MAIN
    mov hMenu,eax
    invoke  LoadAccelerators,hInstance,IDA_MAIN
    mov @hAccelerator,eax

    invoke  RtlZeroMemory,addr @stWndClass,sizeof @stWndClass
    invoke  LoadIcon,hInstance,ICO_MAIN
    mov @stWndClass.hIcon,eax
    mov @stWndClass.hIconSm,eax
    invoke  LoadCursor,0,IDC_ARROW
    mov @stWndClass.hCursor,eax
    push  hInstance
    pop @stWndClass.hInstance
    mov @stWndClass.cbSize,sizeof WNDCLASSEX
    mov @stWndClass.style,CS_HREDRAW or CS_VREDRAW
    mov @stWndClass.lpfnWndProc,offset _ProcWinMain
    mov @stWndClass.hbrBackground,COLOR_BTNFACE+1
    mov @stWndClass.lpszClassName,offset szClassName
    invoke  RegisterClassEx,addr @stWndClass

    invoke  CreateWindowEx,NULL,\
      offset szClassName,offset szCaptionMain,\
      WS_OVERLAPPEDWINDOW,\
      CW_USEDEFAULT,CW_USEDEFAULT,700,500,\
      NULL,hMenu,hInstance,NULL
    mov hWinMain,eax
    invoke  ShowWindow,hWinMain,SW_SHOWNORMAL
    invoke  UpdateWindow,hWinMain

    .while  TRUE
      invoke  GetMessage,addr @stMsg,NULL,0,0
      .break  .if eax == 0
      invoke  TranslateAccelerator,hWinMain,@hAccelerator,addr @stMsg
      .if eax == 0
        invoke  TranslateMessage,addr @stMsg
        invoke  DispatchMessage,addr @stMsg
      .endif
    .endw
    invoke  FreeLibrary,@hRichEdit
    ret
_WinMain  endp

start:
    call  _WinMain
    invoke  ExitProcess,NULL

    end start
