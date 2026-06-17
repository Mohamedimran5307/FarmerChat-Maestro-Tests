import markdown
from weasyprint import HTML

MD_FILE = "/Users/shaikmohamedimran/Documents/Maestro_automation_FarmerChat/FarmerChat_Automation_Report.md"
PDF_FILE = "/Users/shaikmohamedimran/Documents/Maestro_automation_FarmerChat/FarmerChat_Automation_Report.pdf"

with open(MD_FILE, "r") as f:
    md_content = f.read()

html_body = markdown.markdown(md_content, extensions=["tables", "fenced_code"])

html_doc = f"""<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
  @page {{
    size: A4;
    margin: 2cm 1.8cm;
    @top-center {{
      content: "FarmerChat Automation Report";
      font-size: 8pt;
      color: #888;
    }}
    @bottom-center {{
      content: "Page " counter(page) " of " counter(pages);
      font-size: 8pt;
      color: #888;
    }}
  }}
  body {{
    font-family: -apple-system, "Helvetica Neue", Arial, sans-serif;
    font-size: 10pt;
    line-height: 1.6;
    color: #1a1a1a;
  }}
  h1 {{
    font-size: 22pt;
    color: #0d6e3f;
    border-bottom: 3px solid #0d6e3f;
    padding-bottom: 8px;
    margin-top: 0;
  }}
  h2 {{
    font-size: 15pt;
    color: #155a32;
    border-bottom: 1.5px solid #d0d0d0;
    padding-bottom: 5px;
    margin-top: 28px;
    page-break-after: avoid;
  }}
  h3 {{
    font-size: 12pt;
    color: #1a7a45;
    margin-top: 20px;
    page-break-after: avoid;
  }}
  h4 {{
    font-size: 10.5pt;
    color: #333;
    margin-top: 16px;
    page-break-after: avoid;
  }}
  table {{
    width: 100%;
    border-collapse: collapse;
    margin: 12px 0 18px 0;
    font-size: 9pt;
    page-break-inside: auto;
  }}
  tr {{
    page-break-inside: avoid;
  }}
  th {{
    background-color: #0d6e3f;
    color: white;
    padding: 8px 10px;
    text-align: left;
    font-weight: 600;
  }}
  td {{
    padding: 6px 10px;
    border-bottom: 1px solid #e0e0e0;
  }}
  tr:nth-child(even) td {{
    background-color: #f7faf8;
  }}
  code {{
    background-color: #f0f4f0;
    padding: 1px 5px;
    border-radius: 3px;
    font-size: 8.5pt;
    font-family: "SF Mono", Menlo, monospace;
  }}
  pre {{
    background-color: #f5f7f5;
    border: 1px solid #dde3dd;
    border-radius: 4px;
    padding: 12px;
    font-size: 8pt;
    line-height: 1.5;
    overflow-wrap: break-word;
    white-space: pre-wrap;
  }}
  pre code {{
    background: none;
    padding: 0;
  }}
  hr {{
    border: none;
    border-top: 2px solid #0d6e3f;
    margin: 24px 0;
  }}
  strong {{
    color: #0d4a2a;
  }}
  ul, ol {{
    margin: 8px 0;
    padding-left: 24px;
  }}
  li {{
    margin-bottom: 4px;
  }}
  em {{
    color: #555;
  }}
</style>
</head>
<body>
{html_body}
</body>
</html>"""

HTML(string=html_doc).write_pdf(PDF_FILE)
print(f"PDF generated: {PDF_FILE}")
