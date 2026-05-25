from __future__ import annotations

import mimetypes
from pathlib import Path
from typing import Any, BinaryIO, Dict, Optional, Tuple, Union

FileInput = Union[str, Path, bytes, bytearray, BinaryIO]


class PreparedUpload:
    def __init__(self, files: Dict[str, Tuple[str, Any, str]], close_file: Optional[Any] = None) -> None:
        self.files = files
        self.close_file = close_file

    def close(self) -> None:
        if self.close_file:
            self.close_file.close()


def _guess_content_type(filename: str, content_type: Optional[str]) -> str:
    if content_type:
        return content_type
    guessed, _ = mimetypes.guess_type(filename)
    return guessed or "application/octet-stream"


def prepare_upload(
    file: FileInput,
    *,
    filename: Optional[str] = None,
    content_type: Optional[str] = None,
) -> PreparedUpload:
    if isinstance(file, (str, Path)):
        path = Path(file)
        resolved_filename = filename or path.name
        opened = path.open("rb")
        return PreparedUpload(
            {
                "file": (
                    resolved_filename,
                    opened,
                    _guess_content_type(resolved_filename, content_type),
                )
            },
            close_file=opened,
        )

    if isinstance(file, (bytes, bytearray)):
        resolved_filename = filename or "file"
        return PreparedUpload(
            {
                "file": (
                    resolved_filename,
                    bytes(file),
                    _guess_content_type(resolved_filename, content_type),
                )
            }
        )

    resolved_filename = filename or getattr(file, "name", None) or "file"
    if isinstance(resolved_filename, str):
        resolved_filename = Path(resolved_filename).name
    return PreparedUpload(
        {
            "file": (
                str(resolved_filename),
                file,
                _guess_content_type(str(resolved_filename), content_type),
            )
        }
    )

