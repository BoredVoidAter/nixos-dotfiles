{ config, pkgs, lib, ... }:

let
  cfg = config.boredvoidater;

  pyEnv = pkgs.python3.withPackages (ps: with ps; [
    pyicloud
    requests
  ]);

  icloud-reminders = pkgs.writeScriptBin "icloud-reminders" ''
    #!${pyEnv}/bin/python3
    import sys
    import os
    import argparse
    from pyicloud import PyiCloudService

    COOKIE_DIR = os.path.expanduser("~/.local/share/pyicloud")
    APPLE_ID = "${cfg.appleId}"

    def get_client(interactive=False):
        os.makedirs(COOKIE_DIR, exist_ok=True)
        password = ""
        sops_path = "/run/user/1000/secrets/apple_id_password"
        if os.path.exists(sops_path):
            with open(sops_path, "r") as f:
                password = f.read().strip()

        if interactive and not password:
            import getpass
            password = getpass.getpass(f"Enter Apple ID password for {APPLE_ID}: ")

        try:
            api = PyiCloudService(APPLE_ID, password if password else None, cookie_directory=COOKIE_DIR)
        except Exception as e:
            if interactive:
                print(f"Error initializing iCloud session: {e}", file=sys.stderr)
            else:
                print("AUTH_REQUIRED")
            sys.exit(1)

        if api.requires_2fa:
            if not interactive:
                print("2FA_REQUIRED")
                sys.exit(2)
            print("\nTwo-factor authentication required.")
            code = input("Enter the 6-digit code sent to your Apple device: ")
            if not api.validate_2fa_code(code):
                print("Failed to verify 2FA code.", file=sys.stderr)
                sys.exit(1)
            if not api.is_trusted_session:
                print("Requesting trusted session...")
                api.trust_session()
                print("Session trusted successfully!")

        return api

    def main():
        parser = argparse.ArgumentParser(description="Apple Reminders CLI via iCloud")
        subparsers = parser.add_subparsers(dest="command")

        subparsers.add_parser("auth", help="Interactive login and 2FA setup")
        subparsers.add_parser("list", help="List uncompleted reminders")

        add_parser = subparsers.add_parser("add", help="Add a new reminder")
        add_parser.add_argument("title", help="Reminder title")
        add_parser.add_argument("--list", help="Target list name", default=None)

        done_parser = subparsers.add_parser("done", help="Mark reminder as completed")
        done_parser.add_argument("guid", help="Reminder GUID")

        args = parser.parse_args()

        if args.command == "auth":
            get_client(interactive=True)
            print("Successfully authenticated and session saved.")
            return

        if args.command == "list":
            api = get_client(interactive=False)
            try:
                data = api.reminders.lists() if callable(api.reminders.lists) else api.reminders.lists
                for list_name, items in data.items():
                    for item in items:
                        completed = item.get("completedDate") if isinstance(item, dict) else getattr(item, "completedDate", None)
                        if not completed:
                            guid = item.get("guid", "") if isinstance(item, dict) else getattr(item, "guid", "")
                            raw_title = item.get("title", "Untitled") if isinstance(item, dict) else getattr(item, "title", "Untitled")
                            title = str(raw_title).replace("\t", " ").strip()
                            print(f"{guid}\t{list_name}\t{title}")
            except Exception as e:
                print(f"Error listing reminders: {e}", file=sys.stderr)
                sys.exit(1)

        elif args.command == "add":
            api = get_client(interactive=False)
            try:
                collection_id = None
                if args.list:
                    collections = api.reminders.collections() if callable(api.reminders.collections) else getattr(api.reminders, "collections", [])
                    for coll in collections:
                        coll_title = coll.get("title") if isinstance(coll, dict) else getattr(coll, "title", "")
                        if coll_title == args.list:
                            collection_id = coll.get("guid") if isinstance(coll, dict) else getattr(coll, "guid", None)
                            break
                api.reminders.post(title=args.title, collection=collection_id)
                print(f"Created: {args.title}")
            except Exception as e:
                print(f"Error creating reminder: {e}", file=sys.stderr)
                sys.exit(1)

        elif args.command == "done":
            api = get_client(interactive=False)
            try:
                data = api.reminders.lists() if callable(api.reminders.lists) else api.reminders.lists
                for list_name, items in data.items():
                    for item in items:
                        guid = item.get("guid", "") if isinstance(item, dict) else getattr(item, "guid", "")
                        if guid == args.guid:
                            api.reminders.complete(item)
                            raw_title = item.get("title", "Untitled") if isinstance(item, dict) else getattr(item, "title", "Untitled")
                            print(f"Completed: {raw_title}")
                            return
                print(f"Reminder {args.guid} not found", file=sys.stderr)
                sys.exit(1)
            except Exception as e:
                print(f"Error completing reminder: {e}", file=sys.stderr)
                sys.exit(1)
        else:
            parser.print_help()

    if __name__ == "__main__":
        main()
  '';
in
{
  options.boredvoidater.appleId = lib.mkOption {
    type = lib.types.str;
    default = "boredvoidater@icloud.com";
    description = "Apple ID email for iCloud Reminders sync.";
  };

  config = {
    home.packages = [
      icloud-reminders
    ];
  };
}
