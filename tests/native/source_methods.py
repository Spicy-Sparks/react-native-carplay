"""Extract implementation methods without mistaking class-extension prototypes."""
import re


def extract_method(source, signature):
    for match in re.finditer(re.escape(signature), source):
        body = source.find('{', match.end())
        declaration_end = source.find(';', match.end())
        if body < 0 or 0 <= declaration_end < body:
            continue
        end, depth = body + 1, 1
        while depth and end < len(source):
            if source[end] == '{':
                depth += 1
            elif source[end] == '}':
                depth -= 1
            end += 1
        if depth:
            raise ValueError('Unclosed method body: ' + signature)
        return source[match.start():end]
    raise ValueError('No method implementation: ' + signature)
