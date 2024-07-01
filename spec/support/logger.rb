# frozen_string_literal: true

require "logger"
require "stringio"

# Log all box data to a global string io object to test it properly
$box_logger = StringIO.new
Box.logger = Logger.new($box_logger)
