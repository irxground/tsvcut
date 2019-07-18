import os
import strutils
from posix import signal, SIG_PIPE, SIG_IGN

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
