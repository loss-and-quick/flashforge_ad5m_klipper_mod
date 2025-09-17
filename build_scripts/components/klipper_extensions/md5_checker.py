# Hash checking of gcode files
#
# See https://github.com/Klipper3d/klipper/commit/ba2b3909cdc51e4d00521510788a3bf95de273a7
#
# Copyright (C) 2025  minicx <minicx@disroot.org>
#
# This file may be distributed under the terms of the GNU GPLv3 license.
import os
import hashlib
import logging
from typing import Optional

class Md5Check:
    DEFAULT_MD5_PREFIX = " MD5:"
    CHUNK_SIZE = 8192
    
    def __init__(self, config):
        self.name = config.get_name().split()[-1]
        self.printer = config.get_printer()
        self.logger = logging.getLogger('klippy')
        self.gcode = self.printer.lookup_object("gcode")
        
        self.md5_prefix = config.get('md5_prefix', self.DEFAULT_MD5_PREFIX)
        self.checked = False
        
        if not self._init_virtual_sdcard():
            return
        
        self._register_event_handlers()

    def _init_virtual_sdcard(self) -> bool:
        try:
            self.vc = self.printer.lookup_object("virtual_sdcard")
            return True
        except Exception as e:
            self.logger.error(f"{self.name}: virtual_sdcard not found - {e}. MD5 check disabled.")
            self.vc = None
            return False

    def _register_event_handlers(self):
        self.printer.register_event_handler("virtual_sdcard:reset_file", self.on_file_reset)
        self.printer.register_event_handler("virtual_sdcard:load_file", self.on_load_file)

    def on_file_reset(self):
        self.checked = False

    def on_load_file(self):
        if not self.vc or self.checked:
            return
        
        self.checked = True
        
        file_path = self._get_file_path()
        if not file_path:
            return
        
        if not self._validate_file_encoding(file_path):
            return
        
        self._perform_md5_check(file_path)

    def _get_file_path(self) -> Optional[str]:
        try:
            path = self.vc.file_path()
        except Exception as e:
            self.logger.error(f"{self.name}: error obtaining file path - {e}")
            return None
        
        if not path or not os.path.isfile(path):
            self.logger.warning(f"{self.name}: invalid file path: {path}")
            return None
        
        return path

    def _validate_file_encoding(self, file_path: str) -> bool:
        try:
            with open(file_path, "rb") as f:
                f.read().decode('utf-8')
            return True
        except UnicodeDecodeError:
            self._respond_error("File encoding is invalid or corrupted. Canceling print.")
            self._cancel_print()
            return False
        except Exception as e:
            self.logger.error(f"{self.name}: error validating file encoding - {e}")
            self._respond_error(f"Error validating file: {e}")
            return False

    def _perform_md5_check(self, file_path: str):
        try:
            with open(file_path, "rb") as f:
                expected_hash = self._extract_expected_hash(f)
                if not expected_hash:
                    return
                
                actual_hash = self._calculate_file_hash(f)
                self._verify_hashes(expected_hash, actual_hash)
                
        except Exception as e:
            self.logger.error(f"{self.name}: error during MD5 verification - {e}")
            self._respond_error(f"Error during MD5 verification: {e}")

    def _extract_expected_hash(self, file_handle) -> Optional[str]:
        try:
            first_line = file_handle.readline()
            first_line_str = first_line.decode("utf-8", errors="ignore").strip()
        except Exception as e:
            self.logger.warning(f"{self.name}: error reading first line - {e}")
            return None
        
        prefix = f";{self.md5_prefix}"
        if not first_line_str.startswith(prefix):
            self._respond_warn("MD5 comment not found at file start; skipping MD5 check.")
            return None
        
        expected_hash = first_line_str[len(prefix):].strip()
        if not expected_hash:
            self._respond_warn("Empty MD5 hash found; skipping MD5 check.")
            return None
        
        if not self._is_valid_md5_format(expected_hash):
            self._respond_warn(f"Invalid MD5 hash format: {expected_hash}; skipping MD5 check.")
            return None
        
        return expected_hash

    def _is_valid_md5_format(self, hash_str: str) -> bool:
        if len(hash_str) != 32:
            return False
        try:
            int(hash_str, 16)
            return True
        except ValueError:
            return False

    def _calculate_file_hash(self, file_handle) -> str:
        md5_hash = hashlib.md5()
        
        while True:
            chunk = file_handle.read(self.CHUNK_SIZE)
            if not chunk:
                break
            md5_hash.update(chunk)
        
        return md5_hash.hexdigest()

    def _verify_hashes(self, expected: str, actual: str):
        if actual.lower() != expected.lower():
            self._respond_error(
                f"MD5 mismatch: expected {expected}, but computed {actual}. Canceling print."
            )
            self._cancel_print()
        else:
            self._respond_info(f"MD5 verification successful: {actual}. Ready to print.")

    def _cancel_print(self):
        if self.vc:
            self.vc.do_cancel()

    def _respond_info(self, text: str):
        self.gcode.respond_info(f"{self.name}: {text}")

    def _respond_error(self, text: str):
        self.gcode._respond_error(f"{self.name} ERROR: {text}")

    def _respond_warn(self, text: str):
        self.gcode.respond_info(f"{self.name} WARNING: {text}")


def load_config(config):
    return Md5Check(config)