# use this function to replace the escape characters like \\n , \\t , \\r , or consecutive 2 spaces and their ascii equivalents in the text with native Robot escaping syntax.
import re

def normalize_escapes_spaces(text):
        try:
                if isinstance(text, list):
                        text = text[0]
                if re.search(r'(\\n|\\t|\\r|  |\\x0[d,D]|\\x0[a,A]|\\x09)', text):
                        return [text.replace("\\n", "\n").replace("\\r", "\r").replace("\\t", "\t").replace("  ","${SPACE}${SPACE}").replace("\\x0d", "\r").replace("\\x0a", "\n").replace("\\x09", "\t")]
                else:
                        return [text]
        except AttributeError:
                return text