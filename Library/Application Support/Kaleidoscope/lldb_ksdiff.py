# lldb_ksdiff.py v2.4.210312
# to manually install put this in your ~/.lldbinit
"""
command script import /Applications/Kaleidoscope.app/Contents/Resources/Integration/scripts/lldb_ksdiff.py
"""
# to check against python 2 compatibility do
# defaults write com.apple.dt.lldb DefaultPythonVersion 2
# in effect

import lldb
import subprocess
from subprocess import PIPE
import tempfile
import os
import sys
import re
import time
import math
import string

diff_tool_path = '/usr/local/bin/ksdiff'

def __lldb_init_module(debugger, internal_dict):
	debugger.HandleCommand("command script add -f {}.kspo kspo".format(__name__))
	debugger.HandleCommand("command script add -f {}.ksp ksp".format(__name__))

def kspo(debugger, command, result, dict):
	"""\
kspo - pipe objects/object descriptions to Kaleidoscope for inspection and diffing
Automatic support for UIView, UIWindow, UIImage, NSWindow, NSView and NSImage
Usage:
	kspo <object expression>
	
Examples:
	# Compare the descriptions of two array objects
	kspo myArray1
	kspo myArray2

	# Compare two view hierarchies by dumping recursive descriptions
	kspo view1.recursiveDescription
	kspo view2.recursiveDescription
	
	# In Swift (due to it being a private selector)
	kspo view.perform(Selector("recursiveDescription"))!.takeUnretainedValue()

	# Compare two images (NSImage and UIImage automatically supported)
	kspo [UIImage imageNamed:@"FlashOff"]
	kspo [UIImage imageNamed:@"FlashOn2"]
	"""
	
	if not command or command.isspace():
		result.SetError("Missing arguments\n{}".format(kspo.__doc__))
		return
	
	tmp_file_name = dump_object_result_to_tmp_file(debugger, command, result)
	
	if not tmp_file_name:
		return
	
	send_file_to_kaleidoscope(result, "lldb {}".format(debugger.GetSelectedTarget()), tmp_file_name)
	

def ksp(debugger, command, result, dict):
	"""\
ksp - pipe the output of an arbitrary lldb command to Kaleidoscope for inspection and diffing
Usage:
	ksp <any lldb command>
	
Examples:
	# Compare register state
	ksp register read
	ksp register read
	
	# Compare ivar content of self
	ksp p *self
	ksp p *self
	"""
	if not command or command.isspace():
		result.SetError("Missing arguments\n{}".format(ksp.__doc__))
		return
	
	tmp_file_name = dump_command_result_to_tmp_file(debugger, command, result)
	
	if not tmp_file_name:
		return
	send_file_to_kaleidoscope(result, "lldb {}".format(debugger.GetSelectedTarget()), tmp_file_name)

def send_file_to_kaleidoscope(result, title, filename):
	args = [diff_tool_path, "-l", title, filename, "-s"]
	subl = subprocess.Popen(args, stdout=PIPE, stderr=PIPE)
	subl.wait()
	
#	result.SetError("CLI: {}".format(args))
	os.remove(filename)
	
	if subl.returncode != 0:
		out, err = subl.communicate()
		result.SetError("CLI: {}\nksdiff error: {}".format(args, err.decode('utf-8')))
		return
	

def dump_object_result_to_tmp_file(debugger, expression, result):
	currentFrame = debugger.GetSelectedTarget().GetProcess().GetSelectedThread().GetSelectedFrame()
	
	expr_options = lldb.SBExpressionOptions()
	expr_options.SetIgnoreBreakpoints(False);
	expr_options.SetFetchDynamicValue(lldb.eDynamicCanRunTarget);
	expr_options.SetTimeoutInMicroSeconds (30*1000*1000) # 30 second timeout
	expr_options.SetTryAllThreads (True)
	expr_options.SetUnwindOnError(True)
	expr_options.SetGenerateDebugInfo(True)
#	expr_options.SetLanguage (lldb.eLanguageTypeObjC)
	expr_options.SetCoerceResultToId(False)
	
	result_value = currentFrame.EvaluateExpression("{}".format(expression), expr_options)
	
#	print(f"Value: {result_value.GetValue()}")
#	print(f"Value Type: {result_value.GetValueType()}")
#	print(f"Type: {result_value.GetType()}")
#	print(f"Type Name: {result_value.GetTypeName()}")
#	print(f"Declaration: {result_value.GetDeclaration()}")
#	print(f"Display Type Name: {result_value.GetDisplayTypeName()}")
#	print(f"Summary: {result_value.GetSummary()}")
#	print(f"Object Description: {result_value.GetObjectDescription()}")
#	print(f"Pointer: {result_value.GetLocation()}")
#	print(f"Static Value: {result_value.GetStaticValue()}")
#	print(f"Target: {debugger.GetSelectedTarget()}")
	
	error = result_value.GetError()
	if not error.Success():
		result.SetError(error)
		return
	
	bytes, extension = bytes_and_extension_from_result(result_value)

	target_filename = target_filename_for_value(result_value)
	
	result_content = result_value.GetObjectDescription() or result_value.GetSummary()
#	if !result_content:
#		result_content = result_value.GetSummary()
	output = "{}".format(result_content)
	
	target_filename += extension if extension else ".txt"

	bytes = bytes if bytes else output.encode('utf8')
		
	result_filename = write_bytes_to_file_named(bytes, target_filename)
	
	return result_filename

def write_bytes_to_file_named(bytes, filename):
	filepath = os.path.join(tempfile.gettempdir(), filename)
	
	o_file = open(filepath, "wb")
	o_file.write(bytes)
	o_file.close()
	return o_file.name


def target_filename_for_helpful_part(helpful_part):
	time_part = time.strftime("%H-%M-%S")
	nano_time_part = ("{}".format(round(math.modf(time.time())[0],4)))[1:]
	
	valid_chars = "-_.{0}{1}".format(string.ascii_letters, string.digits)
	helpful_part = "".join(ch for ch in helpful_part if ch in valid_chars)
	helpful_part = helpful_part.strip("_ \t\n-")
	
	target_filename = "{}_{}{}".format(helpful_part,time_part,nano_time_part)
	return target_filename

def target_filename_for_value(value):
	helpful_part = value.GetDisplayTypeName().encode('ascii','ignore').decode('ascii').replace(' ','_')
	return target_filename_for_helpful_part(helpful_part)

def dump_command_result_to_tmp_file(debugger, command, result):
	res = lldb.SBCommandReturnObject()
	comminter = debugger.GetCommandInterpreter()
	comminter.HandleCommand(command, res)
	if not res.Succeeded():
		result.SetError("command '{}'\n failed with {}".format(command,res.GetError()))
		return
	output = res.GetOutput()
	bytes = output.encode('utf-8')

	result_filename = write_bytes_to_file_named(bytes, target_filename_for_helpful_part("ksp") + ".txt")
	
	return result_filename

def bytes_and_extension_from_result(result):
	pointer = result.GetValue()
	extension = None

	if is_kind_of_class(pointer, "UIView"):
		value = evaluate_expression("@import UIKit; UIView *v = (UIView *){}; UIGraphicsBeginImageContextWithOptions(v.bounds.size, v.opaque, 0.0f); [v drawViewHierarchyInRect:v.bounds afterScreenUpdates:NO]; UIImage *image = UIGraphicsGetImageFromCurrentImageContext(); UIGraphicsEndImageContext(); image;".format(pointer))
		if value:
			pointer = value.GetValue()
	
	if is_kind_of_class(pointer, "UIImage"):
		value = evaluate_expression("(NSData *)UIImagePNGRepresentation((UIImage *){})".format(pointer))
		if value:
			pointer = value.GetValue()
			extension = ".png"

	if is_kind_of_class(pointer, "NSWindow"):
		value = evaluate_expression("@import Cocoa; [[(NSWindow *){} contentView] superview];".format(pointer));
		print("Result: {}", value.GetError());
		if (value):
			pointer = value.GetValue()


	if is_kind_of_class(pointer, "NSView"):
		value = evaluate_expression("@import Cocoa; NSView *v=(NSView *){}; NSBitmapImageRep *b=[v bitmapImageRepForCachingDisplayInRect:v.bounds]; [b setSize:v.bounds.size]; [v cacheDisplayInRect:v.bounds toBitmapImageRep:b]; NSImage *image=[[NSImage alloc] initWithSize:v.bounds.size]; [image addRepresentation:b]; image;".format(pointer))
		print("Result: {}", value.GetError());
		if value:
			pointer = value.GetValue()
	

	if is_kind_of_class(pointer, "NSImage"):
		value = evaluate_expression("(NSData *)[(NSImage *){} TIFFRepresentation]".format(pointer))
		if value:
			pointer = value.GetValue()
			extension = ".tiff"
	
	bytepointer, length = (None, None)
	
# failed attempt to get to swift data, leaving that here for future improvement though
#	if result.GetTypeName() == "Foundation.Data":
#		bp = result.GetLocation()
#		bs = result.GetByteSize()
#		if bp and bs:
#			bytepointer = int(bp, 16)
#			length = int(bs)
	
	if is_kind_of_class(pointer, "NSData"):
		bp = evaluate_expression("(void *)[(NSData *){} bytes]".format(pointer))
		if bp:
			bs = evaluate_expression("(NSUInteger)[(NSData *){} length]".format(pointer))
			if bs:
				bytepointer = int(bp.GetValue(), 16)
				length = int(bs.GetValue())
	
	if bytepointer and length:
		# print(f"Bytes: {bytepointer} length:{length}")
		
		process = lldb.debugger.GetSelectedTarget().GetProcess()
		error = lldb.SBError()
		mem = process.ReadMemory(bytepointer, length, error)
	
		if error is not None and str(error) != "success":
			print(error)
		else:
			return mem, (extension if extension else ".dump")
	
	return (None,None)

def evaluate_expression(expression):
	frame = lldb.debugger.GetSelectedTarget().GetProcess().GetSelectedThread().GetSelectedFrame()
	options = lldb.SBExpressionOptions();
	options.SetFetchDynamicValue(lldb.eDynamicCanRunTarget);
	options.SetTimeoutInMicroSeconds (30*1000*1000) # 30 second timeout
	options.SetTryAllThreads (True)
	options.SetUnwindOnError(True)
	options.SetGenerateDebugInfo(True)
	options.SetLanguage (lldb.eLanguageTypeObjC_plus_plus)
	options.SetCoerceResultToId(False)

	return frame.EvaluateExpression(expression, options)

def parse_int_result(result):
	output = result.GetValue().replace(
		"'", ""
	)
	if output.startswith("\\x"):  # Booleans may display as \x01 (Hex)
		output = output[2:]
	elif output.startswith("\\"):  # Or as \0 (Dec)
		output = output[1:]
	return int(output, 0)

def evaluate_boolean_expression(expression):
	value = evaluate_expression("(int)({})".format(expression))
# 	print(value.GetError())
# 	print(value.GetError().Success())
	return value.GetError().Success() and parse_int_result(value) != 0

def is_kind_of_class(pointer, class_name):
	return evaluate_boolean_expression("[(id){} isKindOfClass:[{} class]]".format(pointer, class_name))

