#!/usr/bin/env python3

import os
import yaml
from dataclasses import dataclass
from typing import List
from urllib.parse import urlparse, urlunparse

@dataclass
class PolicyMetadata:
    dir: str
    version: str
    description: str
    path: str

def find_policy_yaml(start_dir=".") -> List[str]:
    """Recursively search for files named 'Policy.yaml'."""
    matches = []
    for root, _, files in os.walk(start_dir):
        if "Policy.yaml" in files:
            matches.append(os.path.join(root, "Policy.yaml"))
    return matches

def load_policy_metadata(file_path: str) -> PolicyMetadata:
    """Load a Policy.yaml file and unmarshal it into a PolicyMetadata object."""
    with open(file_path, "r", encoding="utf-8") as f:
        data = yaml.safe_load(f) or {}

    dir_name = os.path.dirname(file_path)
    return PolicyMetadata(
        dir=data.get("dir", dir_name),
        version=data.get("version", ""),
        description=data.get("description", ""),
        path=file_path,
    )

def generate_markdown_table(policies: List[PolicyMetadata]) -> str:
    """Generate a Markdown table from a list of PolicyMetadata objects."""
    header = "| URL | Description | Link |\n"
    separator = "|------------|-----------|---------| \n"
    rows = []
    for p in policies:
        description = p.description.replace("\n", " ").strip()
        ghcr_path = f"ghcr.io/{os.path.normpath(os.path.dirname(p.path))}"
        readme_url = replace_filename_in_url(f"https://github.com/updatecli/policies/tree/main/{p.path}", "README.md")
        rows.append(f"| `{ghcr_path}:{p.version}` | {description or '-'} | {f"[link]({readme_url})" } |")
    return header + separator + "\n".join(rows)

def replace_filename_in_url(url: str, new_filename: str) -> str:
    # Parse the URL
    parsed = urlparse(url)
    
    # Split the path and replace the last part with the new filename
    path_parts = parsed.path.split('/')
    path_parts[-1] = new_filename
    new_path = '/'.join(path_parts)
    
    # Rebuild the URL with the new path
    new_url = urlunparse(parsed._replace(path=new_path))
    return new_url

# Example usage
original_url = "https://github.com/updatecli/policies/blob/main/updatecli/policies/file/Policy.yaml"
new_url = replace_filename_in_url(original_url, "Readme.md")

def main():
    policies = []
    for policy_file in find_policy_yaml("."):
        try:
            metadata = load_policy_metadata(policy_file)
            policies.append(metadata)
        except Exception as e:
            print(f"⚠️ Error parsing {policy_file}: {e}")

    if not policies:
        print("No Policy.yaml files found.")
        return

    markdown = generate_markdown_table(policies)

    with open("POLICIES.md", "w", encoding="utf-8") as f:
        f.write(markdown)

if __name__ == "__main__":
    main()
