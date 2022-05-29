import sys
from RestrictedPython import compile_restricted
from RestrictedPython import safe_globals

source_code = """
def cmd(user_id, args):
    <%= code |> String.replace("\n", "\t\n")%>
"""

loc = {}
byte_code = compile_restricted(source_code, '<inline>', 'exec')
exec(byte_code, safe_globals, loc)
print(loc['cmd'](sys.argv[1], sys.argv[2]))
