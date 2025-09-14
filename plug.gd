#!/usr/bin/env -S godot -s
extends "res://addons/gd-plug/plug.gd"

func _plugging():
	# Testing framework for Godot 4.4
	plug("MikeSchulze/gdUnit4", {"tag": "v5.0.3"})

	# Add future plugins here...