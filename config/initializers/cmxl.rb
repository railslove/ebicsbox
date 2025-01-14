require "cmxl"

Cmxl.config[:statement_separator] = ENV.fetch("CMXL_STATEMENT_SEPARATOR_REGREX", /\n-\s*\n/m)
Cmxl.config[:strip_headers] = true


# /\n-\s*\n/m
# /(\n-?)(?=:20)/m
# /^:(\d{2})(\w)?:(.*)$/

# /(:20:.*?)(?=\n-|\Z)/m
# /\{1:.*?\n-?\}/m
