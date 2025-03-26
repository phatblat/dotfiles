# lldb_ksdiff.py v2.9.250317
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
import base64

diff_tool_path = '/usr/local/bin/ksdiff'
loaded_frameworks = False
is_appkit_available = False
is_uikit_available = False

def __lldb_init_module(debugger, internal_dict):
	debugger.HandleCommand("command script add -f {}.kspo kspo".format(__name__))
	debugger.HandleCommand("command script add -f {}.ksp ksp".format(__name__))
	debugger.HandleCommand("command script add -f {}.ksdiff ksdiff".format(__name__))

def kspo(debugger, command, result, dict):
	"""\
kspo - pipe objects/object descriptions to Kaleidoscope for inspection and diffing
Automatic support for CGImageRef, CIImage, UIView, UIWindow, UIImage, NSWindow, NSView, NSImage and NSBitmapImageRep
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
	
	send_file_to_kaleidoscope(result, debugger.GetSelectedTarget(), tmp_file_name)

def ksp(debugger, command, result, dict):
	"""\
ksp is no longer available. Please use ksdiff instead, it has the same syntax. Usage:
    ksdiff <any lldb command>
	"""
	result.SetError("{}".format(ksp.__doc__))
	return

def ksdiff(debugger, command, result, dict):
	"""\
ksdiff - pipe the output of an arbitrary lldb command to Kaleidoscope for inspection and diffing
Usage:
	ksdiff <any lldb command>
	
Examples:
	# Compare register state
	ksdiff register read
	ksdiff register read
	
	# Compare ivar content of self
	ksdiff p self
	ksdiff p self
	"""
	if not command or command.isspace():
		result.SetError("Missing arguments\n{}".format(ksdiff.__doc__))
		return
	
	tmp_file_name = dump_command_result_to_tmp_file(debugger, command, result)	
	if not tmp_file_name:
		return
	
	send_file_to_kaleidoscope(result, debugger.GetSelectedTarget(), tmp_file_name)

# Private functions

def dump_object_result_to_tmp_file(debugger, expression, result):
	currentFrame = debugger.GetSelectedTarget().GetProcess().GetSelectedThread().GetSelectedFrame()

	expr_options = lldb.SBExpressionOptions()
	expr_options.SetIgnoreBreakpoints(False);
	expr_options.SetFetchDynamicValue(lldb.eDynamicCanRunTarget);
	expr_options.SetTimeoutInMicroSeconds (30*1000*1000) # 30 second timeout
	expr_options.SetTryAllThreads (True)
	expr_options.SetUnwindOnError(True)
	expr_options.SetGenerateDebugInfo(True)
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
#	print(f"Location: {result_value.GetLocation()}")
#	print(f"Static Value: {result_value.GetStaticValue()}")
#	print(f"Target: {debugger.GetSelectedTarget()}")
	
	error = result_value.GetError()
	if not error.Success():
		result.SetError(error)
		return
	
	language = currentFrame.GuessLanguage()
	isObjC = False
	isSwift = False
	if language == lldb.eLanguageTypeObjC:
#		print(f"ObjC detected")
		isObjC = True
	if language == lldb.eLanguageTypeObjC_plus_plus:
#		print(f"ObjC++ detected")
		isObjC = True	
	if language == lldb.eLanguageTypeSwift:
#		print(f"Swift detected")
		isSwift = True
	if isObjC:
		bytes, extension = bytes_and_extension_from_objc_result(result_value)
	if isSwift:
		bytes, extension = bytes_and_extension_from_swift_result(result_value)
	
	encoded_expression = encode_command_for_ksdiff(expression)
	value_type = result_value.GetDisplayTypeName().encode('ascii','ignore').decode('ascii').replace(' ','_')

	helpful_part = encoded_expression + "#" + value_type
	target_filename = temp_filename_for_helpful_part(helpful_part)
	
	result_content = result_value.GetObjectDescription() or result_value.GetSummary()
#	if !result_content:
#		result_content = result_value.GetSummary()
	output = "{}".format(result_content)
	
	target_filename += extension if extension else ".txt"

	bytes = bytes if bytes else output.encode('utf8')
		
	result_filename = write_bytes_to_file_named(bytes, target_filename)
	
	return result_filename

def dump_command_result_to_tmp_file(debugger, command, result):
	res = lldb.SBCommandReturnObject()
	comminter = debugger.GetCommandInterpreter()
	comminter.HandleCommand(command, res)
	if not res.Succeeded():
		result.SetError("command '{}'\n failed with {}".format(command,res.GetError()))
		return
	output = res.GetOutput()
	bytes = output.encode('utf-8')

	helpful_part = encode_command_for_ksdiff(command)
	target_filename = temp_filename_for_helpful_part(helpful_part)
	result_filename = write_bytes_to_file_named(bytes, target_filename + ".txt")

	return result_filename

def temp_filename_for_helpful_part(helpful_part):
	time_part = time.strftime("%H%M%S")
	nano_time_part = ("{}".format(round(math.modf(time.time())[0],4)))[1:]
	target_filename = "{}@{}{}".format(helpful_part,time_part,nano_time_part)
	return target_filename

def bytes_and_extension_from_objc_result(result):
# Import all used frameworks, starting with CoreGraphics. This is necessary because when accessing CGRect directly, it might load a forward declaration that ends in an error in the script. The error message reads: “`CFCGTypes.h:77:13: destructor of ‘CGRect’ is implicitly deleted because field ‘origin’ has no destructor`.”
	global loaded_frameworks
	global is_appkit_available
	global is_uikit_available
	if not loaded_frameworks:
		evaluate_objc_expression("@import CoreGraphics;")
		evaluate_objc_expression("@import CoreImage;")
		evaluate_objc_expression("@import UIKit;")
		evaluate_objc_expression("@import Cocoa;")
		loaded_frameworks = True
		if is_class_available("NSImage"):
			is_appkit_available = True
		if is_class_available("UIImage"):
			is_uikit_available = True

	pointer = result.GetValue()
	extension = None
		
	# We use the prefix KSPO_ for variables inside expressions. Variable names in lldb must not use the same names as the frame context.
		
	# Support CGImageRef
	if result.GetTypeName() == "CGImageRef":
#		print(f"Detected CGImage")
		value = None
		if value == None and is_appkit_available:
			value = evaluate_objc_expression("CGImageRef KSPO_i = (CGImageRef){}; NSBitmapImageRep *KSPO_b = [[NSBitmapImageRep alloc] initWithCGImage:KSPO_i]; KSPO_b;".format(pointer))
		if value == None and is_uikit_available:
			value = evaluate_objc_expression("CGImageRef KSPO_i = (CGImageRef){}; UIImage *KSPO_uii = [UIImage imageWithCGImage:KSPO_i]; KSPO_uii;".format(pointer))
		if value:
			pointer = value.GetValue()
	
	if is_kind_of_class_objc(pointer, "CIImage"):
#		print(f"Detected CIImage")
		value = None
		if value == None and is_appkit_available:
			value = evaluate_objc_expression("CIImage *KSPO_i = (CIImage *){}; NSBitmapImageRep *KSPO_b = [[NSBitmapImageRep alloc] initWithCIImage:KSPO_i]; KSPO_b;".format(pointer))
		if value == None and is_uikit_available:
			value = evaluate_objc_expression("CIImage *KSPO_i = (CIImage *){}; UIImage *KSPO_uii = [UIImage imageWithCIImage:KSPO_i]; KSPO_uii;".format(pointer))
		if value:
			pointer = value.GetValue()
	
	if is_uikit_available and is_kind_of_class_objc(pointer, "UIView"):
#		print(f"Detected UIView")
		value = evaluate_objc_expression("UIView *KSPO_v = (UIView *){}; BOOL KSPO_o = KSPO_v.opaque; CGRect KSPO_r = KSPO_v.bounds; CGSize KSPO_s = KSPO_r.size; UIGraphicsBeginImageContextWithOptions(KSPO_s, KSPO_o, 0.0f); [KSPO_v drawViewHierarchyInRect:KSPO_r afterScreenUpdates:NO]; UIImage *KSPO_snpsht = UIGraphicsGetImageFromCurrentImageContext(); UIGraphicsEndImageContext(); KSPO_snpsht;".format(pointer))
		if value:
			pointer = value.GetValue()
	
	if is_uikit_available and is_kind_of_class_objc(pointer, "UIImage"):
#		print(f"Detected UIImage")
		value = evaluate_objc_expression("(NSData *)UIImagePNGRepresentation((UIImage *){})".format(pointer))
		if value:
			pointer = value.GetValue()
			extension = ".png"
	
	if is_appkit_available and is_kind_of_class_objc(pointer, "NSWindow"):
#		print(f"Detected NSWindow")
		value = evaluate_objc_expression("[[(NSWindow *){} contentView] superview];".format(pointer));
		if value:
			pointer = value.GetValue()
	
	if is_appkit_available and is_kind_of_class_objc(pointer, "NSView"):
#		print(f"Detected NSView")
		value = evaluate_objc_expression("NSView *KSPO_v = (NSView *){}; NSRect KSPO_r = [KSPO_v bounds]; NSSize KSPO_s = KSPO_r.size; NSBitmapImageRep *KSPO_b = [KSPO_v bitmapImageRepForCachingDisplayInRect:KSPO_r]; [KSPO_b setSize:KSPO_s]; [KSPO_v cacheDisplayInRect:KSPO_r toBitmapImageRep:KSPO_b]; KSPO_b;".format(pointer))
		if value:
			pointer = value.GetValue()
	
	if is_appkit_available and is_kind_of_class_objc(pointer, "NSBitmapImageRep"):
#		print(f"Detected NSBitmapImageRep")
		value = evaluate_objc_expression("(NSData *)[(NSBitmapImageRep *){} TIFFRepresentation]".format(pointer))
		if value:
			pointer = value.GetValue()
			extension = ".tiff"
	
	if is_appkit_available and is_kind_of_class_objc(pointer, "NSImage"):
#		print(f"Detected NSImage")
		value = evaluate_objc_expression("(NSData *)[(NSImage *){} TIFFRepresentation]".format(pointer))
		if value:
			pointer = value.GetValue()
			extension = ".tiff"
	
	bytepointer, length = (None, None)

	if is_kind_of_class_objc(pointer, "NSData"):
#		print(f"Detected NSData")
		bp = evaluate_objc_expression("(void *)[(NSData *){} bytes]".format(pointer))
		if bp:
			bs = evaluate_objc_expression("(NSUInteger)[(NSData *){} length]".format(pointer))
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

def evaluate_objc_expression(expression):
	frame = lldb.debugger.GetSelectedTarget().GetProcess().GetSelectedThread().GetSelectedFrame()
	options = lldb.SBExpressionOptions();
	options.SetFetchDynamicValue(lldb.eDynamicCanRunTarget);
	options.SetTimeoutInMicroSeconds (30*1000*1000) # 30 second timeout
	options.SetTryAllThreads (True)
	options.SetUnwindOnError(True)
	options.SetGenerateDebugInfo(True)
	options.SetLanguage (lldb.eLanguageTypeObjC)
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

def evaluate_boolean_expression_objc(expression):
	result = False
	value = evaluate_objc_expression("(int)({})".format(expression))
	if value.error.Success():
		return parse_int_result(value) != 0
	else:
		print("Error (evaluate_boolean_expression_objc):", value.error)
	return result

def is_kind_of_class_objc(pointer, class_name):
	return evaluate_boolean_expression_objc("[(id){} isKindOfClass:[{} class]]".format(pointer, class_name))

def is_class_available(class_name):
	return evaluate_boolean_expression_objc("(Class)NSClassFromString(@\"{}\") != nil".format(class_name))

def bytes_and_extension_from_swift_result(result):
	pointer = result.GetValue()
	extension = None
	
#	print("Pointer: {}".format(pointer) )

	if pointer == None or not "0x" in pointer:
		# This happens for eg. value types like Int, String and Data
#		print("No pointer to interpret ({})".format(type(result)))
		return (None,None)
	
	global loaded_frameworks
	global is_appkit_available
	global is_uikit_available
	
	if not loaded_frameworks:
		evaluate_swift_expression("import CoreGraphics")
		evaluate_swift_expression("import CoreImage")
		evaluate_swift_expression("import Cocoa")
		evaluate_swift_expression("import UIKit")
		loaded_frameworks = True
		
		if is_class_available("NSImage"):
#			print(f"Found AppKit")
			is_appkit_available = True
		if is_class_available("UIImage"):
#			print(f"Found UIKit")
			is_uikit_available = True
	
	if "CGImageRef" in result.GetTypeName():
#		print(f"CGImage detected (Swift)")
		value = None
		if is_uikit_available:
			value = evaluate_swift_expression("let KSPO_cgImage = unsafeBitCast({}, to: CGImage.self); let KSPO_image = UIImage(cgImage: KSPO_cgImage); KSPO_image".format(pointer));
		if is_appkit_available:
			value = evaluate_swift_expression("let KSPO_cgImage = unsafeBitCast({}, to: CGImage.self); let KSPO_image = NSImage(cgImage:KSPO_cgImage, size:.zero); KSPO_image;".format(pointer));
		
		if type(value) == lldb.SBValue:
			if value.error.Success():
				pointer = value.GetValue()
			else:
				print("Error: ", value.error)

	
	if is_kind_of_class_swift(pointer, "CIImage"):
#		print(f"CIImage detected (Swift)")
		value = None
		if is_uikit_available:
			value = evaluate_swift_expression("let KSPO_ciImage = unsafeBitCast({}, to: CIImage.self); let KSPO_image = UIImage(ciImage: KSPO_ciImage); KSPO_image".format(pointer));
		if is_appkit_available:
			value = evaluate_swift_expression("let KSPO_ciImage = unsafeBitCast({}, to: CIImage.self); let KSPO_image = NSImage(cgImage:KSPO_ciImage.cgImage!, size:.zero); KSPO_image;".format(pointer));
		
		if type(value) == lldb.SBValue:
			if value.error.Success():
				pointer = value.GetValue()
			else:
				print("Error: ", value.error)
	
	if is_uikit_available and is_kind_of_class_swift(pointer, "UIView"):
#		print(f"UIView detected (Swift)")
		value = evaluate_swift_expression("let KSPO_view = unsafeBitCast({}, to: UIView.self); let KSPO_bounds = KSPO_view.bounds; let KSPO_size = KSPO_bounds.size; let KSPO_opaque = KSPO_view.isOpaque; UIGraphicsBeginImageContextWithOptions(KSPO_size, KSPO_opaque, 0.0); KSPO_view.drawHierarchy(in: KSPO_bounds, afterScreenUpdates: false); let KSPO_image = UIGraphicsGetImageFromCurrentImageContext(); UIGraphicsEndImageContext(); KSPO_image;".format(pointer));
		if value.error.Success():
			pointer = value.GetValue()
		else:
			print("Error: ", value.error)
	
	if is_uikit_available and is_kind_of_class_swift(pointer, "UIImage"):
#		print(f"UIImage detected (Swift)")
		value = evaluate_swift_expression("let KSPO_image = unsafeBitCast({}, to: UIImage.self); KSPO_image.pngData() as NSData?".format(pointer))
		if value.error.Success():
			pointer = value.GetValue()
			extension = ".png"
		else:
			print("Error: ", value.error)
	
	if is_appkit_available and is_kind_of_class_swift(pointer, "NSWindow"):
#		print(f"NSWindow detected (Swift)")
		value = evaluate_swift_expression("let KSPO_window = unsafeBitCast({}, to: NSWindow.self); KSPO_window.contentView!.superview;".format(pointer))
		if value.error.Success():
			pointer = value.GetValue()
		else:
			print("Error: ", value.error)
	
	if is_appkit_available and is_kind_of_class_swift(pointer, "NSView"):
#		print(f"NSView detected (Swift)")
		value = evaluate_swift_expression("let KSPO_view = unsafeBitCast({}, to: NSView.self); let KSPO_r = KSPO_view.bounds; let KSPO_s = KSPO_r.size; var KSPO_b = KSPO_view.bitmapImageRepForCachingDisplay(in: KSPO_r); KSPO_b!.size = KSPO_s; KSPO_view.cacheDisplay(in: KSPO_r, to: KSPO_b!); KSPO_b;".format(pointer))
		if value.error.Success():
			pointer = value.GetValue()
		else:
			print("Error: ", value.error)

	if is_appkit_available and is_kind_of_class_swift(pointer, "NSBitmapImageRep"):
#		print(f"NSBitmapImageRep detected (Swift)")
		value = evaluate_swift_expression("let KSPO_b = unsafeBitCast({}, to: NSBitmapImageRep.self); KSPO_b.tiffRepresentation(using: .none, factor: 0) as NSData?;".format(pointer))
		if value.error.Success():
			pointer = value.GetValue()
			extension = ".tiff"
		else:
			print("Error: ", value.error)
	
	if is_appkit_available and is_kind_of_class_swift(pointer, "NSImage"):
#		print(f"NSImage detected (Swift)")
		value = evaluate_objc_expression("(NSData *)[(NSImage *){} TIFFRepresentation]".format(pointer))
		if value.error.Success():
			pointer = value.GetValue()
			extension = ".tiff"
		else:
			print("Error: ", value.error)
	
	bytepointer, length = (None, None)
	
	if is_kind_of_class_swift(pointer, "Data"):
#		print(f"Data detected (Swift)")
		bp = evaluate_objc_expression("(void *)[(NSData *){} bytes]".format(pointer))
		if bp:
			bs = evaluate_objc_expression("(NSUInteger)[(NSData *){} length]".format(pointer))
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

def evaluate_swift_expression(expression):
	frame = lldb.debugger.GetSelectedTarget().GetProcess().GetSelectedThread().GetSelectedFrame()
	options = lldb.SBExpressionOptions();
	options.SetFetchDynamicValue(lldb.eDynamicCanRunTarget);
	options.SetTimeoutInMicroSeconds (30*1000*1000) # 30 second timeout
	options.SetTryAllThreads (True)
	options.SetUnwindOnError(True)
	options.SetGenerateDebugInfo(True)
	options.SetLanguage (lldb.eLanguageTypeSwift)
	options.SetCoerceResultToId(False)

	value = frame.EvaluateExpression(expression, options)
	
#	if not value.error.Success() and value:
#		print("", value)
	
	return value

def evaluate_boolean_expression_swift(expression):
	result = False
	value = evaluate_swift_expression("{} ? 1 : 0".format(expression))
	if value.error.Success():
		output = value.GetValue()
		result = int(output, 0)
#	else:
#		print("Error (evaluate_boolean_expression_swift):", value.error)
	return result

def is_kind_of_class_swift(pointer, class_name):
	return evaluate_boolean_expression_swift("let object = unsafeBitCast({}, to: AnyObject.self); object is {}".format(pointer, class_name))

def encode_command_for_ksdiff(command):
	# Shorten the command to a maximum of 50 characters
	short_command = command[:50]
	# Encode the string command as base64, so we can use it in the filename
	base64_command = base64.urlsafe_b64encode(short_command.encode('utf-8')).decode('utf-8')
	return base64_command

def write_bytes_to_file_named(bytes, filename):
	filepath = os.path.join(tempfile.gettempdir(), filename)
	
	o_file = open(filepath, "wb")
	o_file.write(bytes)
	o_file.close()
	return o_file.name

def send_file_to_kaleidoscope(result, target, filename):
	name = "Debugging {}".format(target)
	args = [diff_tool_path, "-l", name, filename, "-s"]
	subl = subprocess.Popen(args, stdout=PIPE, stderr=PIPE)
	subl.wait()
	
#	result.SetError("CLI: {}".format(args))
	os.remove(filename)
	
	if subl.returncode != 0:
		out, err = subl.communicate()
		result.SetError("CLI: {}\nksdiff error: {}".format(args, err.decode('utf-8')))
		return
	
