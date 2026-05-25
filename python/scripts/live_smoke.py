from __future__ import annotations

import os
import sys

from buble_ai import Buble, BubleAPIError


def check(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def main() -> int:
    if not os.environ.get("BUBLE_API_KEY"):
        print("Missing BUBLE_API_KEY.", file=sys.stderr)
        return 1

    client = Buble()

    models = client.media_models.list()
    check(isinstance(models.get("data"), list), "media_models.list() should return data list")
    print(f"PASS media_models.list(): {len(models['data'])} models")

    image_models = client.media_models.list(media_type="image")
    check(isinstance(image_models.get("data"), list), "filtered media_models.list() should return data list")
    print(f"PASS media_models.list(media_type='image'): {len(image_models['data'])} models")

    apps = client.apps.list(limit=10)
    check(isinstance(apps.get("data"), list), "apps.list() should return data list")
    print(f"PASS apps.list(): {len(apps['data'])} apps")

    if apps["data"]:
        app_id = apps["data"][0]["id"]
        app = client.apps.retrieve(app_id)
        check(app["data"]["id"] == app_id, "apps.retrieve() should return requested id")
        print(f"PASS apps.retrieve({app_id})")

    chat_models = client.chat.models.list()
    check(chat_models.get("object") == "list", "chat.models.list() should preserve object=list")
    check(isinstance(chat_models.get("data"), list), "chat.models.list() should return data list")
    print(f"PASS chat.models.list(): {len(chat_models['data'])} models")

    try:
        client.generations.retrieve("sdk-smoke-non-existent-task")
    except BubleAPIError as error:
        check(error.status_code >= 400, "expected API error for non-existent task")
        print(f"PASS BubleAPIError parsing: {error.status_code} {error.code or ''}".strip())
    else:
        raise AssertionError("non-existent task should not succeed")

    client.close()
    print("PASS live smoke test completed without creating billable generation tasks")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

