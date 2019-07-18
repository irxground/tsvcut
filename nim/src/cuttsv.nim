import os
import strutils
from posix import signal, SIG_PIPE, SIG_IGN

proc readLine*(f: File, line: var TaintedString): bool {.tags: [ReadIOEffect].} =
  ## reads a line of text from the file `f` into `line`. May throw an IO
  ## exception.
  ## A line of text may be delimited by ``LF`` or ``CRLF``. The newline
  ## character(s) are not part of the returned string. Returns ``false``
  ## if the end of the file has been reached, ``true`` otherwise. If
  ## ``false`` is returned `line` contains no new data.
  proc c_memchr(s: pointer, c: cint, n: csize): pointer {.
    importc: "memchr", header: "<string.h>".}
  proc c_memset(s: pointer, c: cint, n: csize) {.
    importc: "memset", header: "<string.h>".}
  proc c_fgets(c: cstring, n: cint, f: File): cstring {.
    importc: "fgets", header: "<stdio.h>", tags: [ReadIOEffect].}

  var pos = 0

  # Use the currently reserved space for a first try
  var sp = max(line.string.len, 80)
  # var sp = 80
  line.string.setLen(sp)

  while true:
    # memset to \L so that we can tell how far fgets wrote, even on EOF, where
    # fgets doesn't append an \L
    # line.string[pos] = '\L'
    # for i in pos..<pos+sp: line.string[i] = '\L'
    c_memset(addr line.string[pos], '\L'.ord, sp)

    var fgetsSuccess = c_fgets(addr line.string[pos], sp.cint, f) != nil
    if not fgetsSuccess: return false
    let m = c_memchr(addr line.string[pos], '\L'.ord, sp)
    if m != nil:
      # \l found: Could be our own or the one by fgets, in any case, we're done
      var last = cast[ByteAddress](m) - cast[ByteAddress](addr line.string[0])
      if last > 0 and line.string[last-1] == '\c':
        line.string.setLen(last-1)
        return last > 1 or fgetsSuccess
        # We have to distinguish between two possible cases:
        # \0\l\0 => line ending in a null character.
        # \0\l\l => last line without newline, null was put there by fgets.
      elif last > 0 and line.string[last-1] == '\0':
        if last < pos + sp - 1 and line.string[last+1] != '\0':
          dec last
      line.string.setLen(last)
      return last > 0 or fgetsSuccess
    else:
      # fgets will have inserted a null byte at the end of the string.
      dec sp
    # No \l found: Increase buffer and read more
    inc pos, sp
    sp = 128 # read in 128 bytes at a time
    line.string.setLen(pos+sp)

proc findIndex(heystack: string, needle: string, sep: string): int =
  var ix = 0
  for item in heystack.split(sep, -1):
    if item == needle:
      return ix
    inc(ix)
  return -1

proc main() =
  if os.paramCount() == 0:
    stderr.writeLine("Field name is required.")
    quit(1)
  let field = os.paramStr(1)
  var line = ""
  if readLine(stdin, line) == false:
    stderr.writeLine("Fail to read first line.")
    quit(1)
  let index = findIndex(line, field, "\t")
  if index < 0:
    stderr.writeLine("Field name `", field, "`is not found.")
    quit(1)

  stdout.write(field, "\n")
  stdout.flushFile()
  while readLine(stdin, line):
    var i = -1
    for cell in line.split("\t"):
      inc(i)
      if i != index:
        continue
      stdout.write(cell, "\n")
      break
  stdout.flushFile()

when isMainModule:
  signal(SIG_PIPE, SIG_IGN)
  try:
    main()
  except IOError:
    discard()
