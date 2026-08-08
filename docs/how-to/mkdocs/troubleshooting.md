# Troubleshooting

## Common Issues

### mkdocs: command not found

Cause

Python Virtual Environment belum aktif.

Resolution

source ~/venv/mkdocs/bin/activate

---

### ModuleNotFoundError

Cause

Plugin belum terinstall.

Resolution

pip install ...

---

### Failed to build documentation

Cause

Kesalahan sintaks Markdown atau mkdocs.yml.

Resolution

Periksa pesan error kemudian jalankan kembali.

---

### Mermaid Diagram Not Rendered

Cause

markdown_extensions belum dikonfigurasi.

Resolution

Tambahkan konfigurasi yang diperlukan.

---

### CSS Not Applied

Cause

extra_css belum dikonfigurasi.

Resolution

Periksa konfigurasi pada mkdocs.yml.

---

### Broken Hyperlinks

Cause

Relative path salah.

Resolution

Periksa struktur direktori dan hyperlink.