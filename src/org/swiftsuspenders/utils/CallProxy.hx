package org.swiftsuspenders.utils;

/**
 * ...
 * @author P.J.Shand
 */
class CallProxy
{

	public function new() 
	{
		
	}
	
	public static function getClassName(c : Class<Dynamic> ) : String
	{
		var className = Type.getClassName(c);
		className = className.split("flash.").join("openfl.");
		return className;
	}
	
	public static function hasField( o:Dynamic, field:String):Bool
	{
		#if js
			var f:Dynamic = Reflect.getProperty(o, field);
			var isFunction = Reflect.isFunction(f);
			var isObject = Reflect.isObject(f);
			if (isFunction || isObject) return true;
			else return false;
		#else 
			var hasField = Reflect.hasField(o, field);
			return hasField;
		#end
	}
}