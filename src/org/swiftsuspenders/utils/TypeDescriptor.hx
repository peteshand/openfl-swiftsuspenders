/*
 * Copyright (c) 2012 the original author or authors
 *
 * Permission is hereby granted to use, modify, and distribute this file
 * in accordance with the terms of the license agreement accompanying it.
 */

package org.swiftsuspenders.utils;

import openfl.utils.Dictionary;

import org.swiftsuspenders.reflection.Reflector;
import org.swiftsuspenders.typedescriptions.TypeDescription;

class TypeDescriptor
{
	//----------------------       Private / Protected Properties       ----------------------//
	public var _descriptionsCache:Dictionary;
	private var _reflector:Reflector;


	//----------------------               Public Methods               ----------------------//
	public function new(reflector:Reflector, descriptionsCache:Dictionary)
	{
		_descriptionsCache = descriptionsCache;
		_reflector = reflector;
	}

	public function getDescription(type:Class):TypeDescription
	{
		//get type description or cache it if the given type wasn't encountered before
		return _descriptionsCache[type] ||= _reflector.describeInjections(type);
	}

	public function addDescription(type:Class, description:TypeDescription):Void
	{
		_descriptionsCache[type] = description;
	}
}