import re

class Filter:
    name = "normalize_special_string"

    @classmethod
    def filter(cls, text):
        """
        JINJA Filter to 
        1) escape consecutive 2 spaces in the text with native Robot escaping syntax.
        2) escape special characters like \n, \t, \r for Robot Framework.
        """
        try:
            return text.replace("  ","${SPACE}${SPACE}").replace("\n", "\\n").replace("\r", "\\r").replace("\t", "\\t")
        except AttributeError:
            return text