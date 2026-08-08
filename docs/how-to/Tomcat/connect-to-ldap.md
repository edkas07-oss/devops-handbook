# Review JNDIRealm tanpa admin

> kamu bisa review config berikut, jadi saya inginnya tidak menggunakan connection name, karena tidak mungkin perusahaan besar memberikan user admin dan passwordnya. kamu ada ide ? tomcat dan openldap menggunakan podman.
>
> <Realm className="org.apache.catalina.realm.LockOutRealm">
>                 <Realm className="org.apache.catalina.realm.UserDatabaseRealm" resourceName="UserDatabase"/>
>                 <Realm className="org.apache.catalina.realm.JNDIRealm"
>                      connectionURL="ldap://openldap:389"
>                      connectionName="cn=admin,dc=lab,dc=local"
>                      connectionPassword="Password123"
>                      userPattern="uid={0},ou=users,dc=lab,dc=local"
>                      roleBase="ou=groups,dc=lab,dc=local"
>                      roleName="cn"
>                      roleSearch="(|(uniqueMember={0})(member={0})(memberUid={1}))"
>                      roleSearchAsUser="true"
>                      roleSubtree="true" />
>                 </Realm>
>
> config tersebut ada didalam file server.xml

<details><summary>2 previous messages</summary>

> Saya akan cek semantik `JNDIRealm`—terutama bind anonim dan `roleSearchAsUser`—agar rekomendasinya aman untuk OpenLDAP di Podman.
>
> <details><summary>Searched the web</summary>
>
> Searched the web for `site:tomcat.apache.org tomcat JNDIRealm connectionName roleSearchAsUser ...`
>
> Searched the web for `site:tomcat.apache.org tomcat JNDIRealm connectionName roleSearchAsUser ...`
>
> </details>
</details>

Bisa. Jangan gunakan akun `cn=admin`; opsi terbaik adalah bind sebagai user yang sedang login. Dengan `userPattern`, Tomcat dapat mencoba LDAP simple bind menggunakan DN user dan password yang dikirim saat login.

Hapus `connectionName` dan `connectionPassword`:

```xml
<Realm className="org.apache.catalina.realm.LockOutRealm">
  <Realm className="org.apache.catalina.realm.JNDIRealm"
         connectionURL="ldap://openldap:389"
         userPattern="uid={0},ou=users,dc=lab,dc=local"
         roleBase="ou=groups,dc=lab,dc=local"
         roleName="cn"
         roleSearch="(|(uniqueMember={0})(member={0})(memberUid={1}))"
         roleSearchAsUser="true"
         roleSubtree="true" />
</Realm>
```

Catatan penting:

- Pastikan tidak ada atribut `userPassword`. Jika atribut itu disetel, Tomcat perlu membaca hash password dari LDAP—biasanya memerlukan service account.
- `roleSearchAsUser="true"` membuat pencarian grup dilakukan dengan kredensial user yang sudah berhasil bind. OpenLDAP perlu ACL agar semua user yang valid boleh membaca entry grup dan atribut `cn`, `member`, `uniqueMember`, atau `memberUid` yang diperlukan.
- Hindari `ldap://` untuk lingkungan nyata. Gunakan LDAPS atau StartTLS, misalnya `ldaps://openldap:636`, serta truststore Java berisi CA sertifikat LDAP.
- Nama host `openldap` valid jika container Tomcat dan OpenLDAP berada pada network Podman yang sama dan alias/service itu tersedia.
- Config Anda memiliki dua nested realm (`UserDatabaseRealm` dan `JNDIRealm`) di dalam `LockOutRealm`. Untuk autentikasi LDAP saja, hapus `UserDatabaseRealm`; jangan mengandalkan keduanya sebagai fallback otomatis.

Jika ACL perusahaan tidak mengizinkan user membaca keanggotaan grup, solusi yang lazim dan aman bukan admin password, melainkan akun teknis khusus read-only dengan hak minimal pada `ou=users` dan `ou=groups`. Dokumentasi Tomcat sendiri menyarankan akun LDAP read-only bila diperlukan, dan `JNDIRealm` memang akan melakukan simple bind user bila `userPassword` tidak dikonfigurasi. [Tomcat Realm configuration](https://tomcat.apache.org/tomcat-9.0-doc/config/realm.html)

> kamu tidak bisa langsung merevisi yah ?

<details><summary>3 previous messages</summary>

> Bisa—saya akan langsung cari konfigurasi `server.xml`, revisi Realm LDAP agar memakai bind user, lalu cek perubahan.
>
> `server.xml` tidak ada di repository `nginx-automation` (isinya playbook Nginx). Saya cek workspace terkait untuk menemukan file Tomcat yang tepat tanpa menyentuh perubahan Anda.
>
> <details><summary>Edited a file</summary>
>
> - Wrote `~/tomcat-data/conf/server.xml` (+11 -14)
>
> </details>
</details>

Sudah saya revisi [server.xml](~/tomcat-data/conf/server.xml:166).

- Menghapus kredensial admin LDAP.
- Menghapus `UserDatabaseRealm` yang tidak diperlukan.
- Tomcat sekarang autentikasi langsung memakai DN dan password user.
- Validasi XML (`xmllint`) berhasil.

Pastikan ACL OpenLDAP mengizinkan user yang login membaca grup yang relevan, karena `roleSearchAsUser="true"`.

> saya minta kamu restart dan lakukan tes

<details><summary>3 previous messages</summary>

> Saya akan identifikasi container Tomcat dan OpenLDAP, lalu restart Tomcat dan uji log/endpoint autentikasinya.
>
> Container yang aktif adalah `tomcat-app1` dan `openldap`. File yang diubah berada di host; saya cek dulu bahwa file tersebut memang ter-mount sebagai `server.xml` Tomcat, lalu restart container Tomcat.
>
> Restart berhasil dan konfigurasi baru termuat. Namun log lama menunjukkan kegagalan saat mencari role karena DN `ou=groups,dc=lab,dc=local` tidak ada. Saya cek struktur LDAP dan respons Tomcat untuk memisahkan masalah konfigurasi role dari konektivitas/bind.
</details>

Tomcat sudah direstart dan HTTP-nya sehat: `http://127.0.0.1:8083/` mengembalikan **200**.

Hasil tes konfigurasi LDAP:

- Direct bind user terbukti berjalan: log OpenLDAP mencatat bind sukses sebagai `uid=edkas07,ou=users,dc=lab,dc=local`.
- Tetapi otorisasi role gagal karena base yang dikonfigurasi tidak ada:

```text
ou=groups,dc=lab,dc=local → LDAP error 32: No Such Object
```

Jadi penghapusan akun admin sudah benar; blocker-nya sekarang adalah struktur grup LDAP, bukan autentikasi user. Saya perlu DN group yang benar (misalnya mungkin `ou=group,...`, `ou=roles,...`, atau grup berada langsung di bawah `dc=lab,dc=local`) untuk membetulkan `roleBase` dan melakukan tes login end-to-end.

Benar—saya koreksi: screenshot itu menunjukkan `roleBase` saya **sudah benar**:

```text
ou=groups,dc=lab,dc=local
└── cn=manager-gui
    └── uniqueMember=uid=edkas07,ou=users,dc=lab,dc=local
```

Filter dan mapping saat ini juga sesuai dengan struktur tersebut:

```xml
roleSearch="(|(uniqueMember={0})(member={0})(memberUid={1}))"
roleName="cn"
```

Error `No Such Object` kemungkinan karena `roleSearchAsUser="true"`: setelah bind sebagai `edkas07`, ACL OpenLDAP menyembunyikan/melarang user membaca `ou=groups`. phpLDAPadmin dapat melihatnya karena login sebagai admin.

Agar tanpa akun admin/service account, ACL OpenLDAP perlu mengizinkan user terautentikasi membaca grup dan atribut yang dipakai:

```ldif
olcAccess: to dn.subtree="ou=groups,dc=lab,dc=local"
  attrs=entry,cn,uniqueMember,member,memberUid
  by users read
  by * none
```

Jadi config Tomcat yang sudah direvisi tetap tepat. Yang perlu diubah adalah ACL LDAP, lalu saya bisa restart OpenLDAP/Tomcat dan tes login end-to-end—saya butuh password user uji seperti `edkas07` untuk tes tersebut.

> gimana cara ubah ACL LDAPnya ?

<details><summary>2 previous messages</summary>

> Saya akan lihat ACL yang aktif secara read-only agar contoh LDIF tidak menimpa aturan yang sudah ada; ACL OpenLDAP harus ditambahkan sebagai aturan baru, bukan mengganti seluruh `olcAccess`.
>
> ACL aktif mengonfirmasi penyebabnya: aturan terakhir hanya memberi `self read`, sehingga user seperti `edkas07` tidak bisa membaca entry grup. Saya cek jalur socket lokal OpenLDAP untuk perintah perubahan yang aman.
</details>

ACL aktifnya memang hanya memberi akses baca kepada entry milik sendiri:

```text
to * by self read ... by * none
```

Tambahkan aturan sebelum aturan generik itu, supaya semua user yang sudah login LDAP dapat mencari grup. Jalankan dari host:

```bash
podman exec -i openldap ldapmodify -Y EXTERNAL -H ldapi:/// <<'LDIF'
dn: olcDatabase={1}mdb,cn=config
changetype: modify
add: olcAccess
olcAccess: {2}to dn.subtree="ou=groups,dc=lab,dc=local" attrs=entry,cn,uniqueMember,member,memberUid by users read by * none
LDIF
```

Perintah ini tidak memakai password admin LDAP: autentikasi dilakukan melalui socket lokal container (`ldapi:///`). Aturan `{2}` ditempatkan sebelum aturan umum yang sekarang menjadi urutan berikutnya.

Lalu tes sebagai user LDAP—password diminta interaktif, jadi tidak muncul di history command:

```bash
podman exec -it openldap ldapsearch -LLL -x \
  -H ldap://localhost:389 \
  -D 'uid=edkas07,ou=users,dc=lab,dc=local' -W \
  -b 'ou=groups,dc=lab,dc=local' \
  '(uniqueMember=uid=edkas07,ou=users,dc=lab,dc=local)' cn
```

Output yang diharapkan:

```text
dn: cn=manager-gui,ou=groups,dc=lab,dc=local
cn: manager-gui
```

Tidak perlu restart OpenLDAP karena `cn=config` diterapkan dinamis. Setelah tes LDAP sukses, restart Tomcat agar cache/lockout dibersihkan:

```bash
podman restart tomcat-app1
```

Untuk data pada screenshot, Anda juga bisa menyederhanakan filter Tomcat menjadi `roleSearch="(uniqueMember={0})"` karena grupnya adalah `groupOfUniqueNames`; filter sekarang tetap kompatibel.

> maksudnya gimana yah ? kamu memerintahkan saya atau gimana ?

Maaf, saya sedang menjelaskan langkah yang perlu dilakukan—bukan berarti saya sudah mengubah ACL-nya.

Perubahan ACL adalah perubahan kebijakan akses LDAP, jadi saya belum menjalankannya tanpa persetujuan Anda. Jika Anda setuju, saya bisa langsung:

1. menambahkan ACL agar user LDAP boleh membaca grup,
2. tes akses sebagai user,
3. restart Tomcat,
4. laporkan hasilnya.

Cukup balas: **“lanjut ubah ACL”**.

> lanjut ubah ACL

<details><summary>4 previous messages</summary>

> Baik. Saya akan menambahkan ACL read-only khusus untuk subtree grup, verifikasi bahwa aturan aktif, lalu tes pencarian grup dengan akun LDAP secara interaktif bila kredensial uji tersedia.
>
> ACL berhasil diterapkan secara dinamis. Sekarang saya verifikasi urutan ACL-nya, restart Tomcat untuk membersihkan status lockout, dan cek endpoint aplikasi yang benar untuk pengujian autentikasi.
>
> Tomcat masih menyelesaikan startup saat cek pertama sehingga koneksi sempat ter-reset. Saya tunggu singkat lalu ulangi pemeriksaan endpoint Manager.
>
> Tomcat sebenarnya sudah aktif dan log menunjukkan startup selesai normal. Cek sebelumnya berasal dari sandbox jaringan; saya ulangi dari host runtime yang sama untuk mendapatkan status HTTP yang valid.
</details>

ACL OpenLDAP sudah ditambahkan dan aktif:

- User LDAP terautentikasi dapat membaca `ou=groups,dc=lab,dc=local`.
- Aksesnya read-only; tidak ada akses tulis.
- Tomcat sudah direstart dan startup normal.
- `/manager/html` sekarang merespons **HTTP 401** tanpa kredensial—endpoint proteksinya aktif.

Saya belum bisa membuktikan login berhasil tanpa password user uji `edkas07`. Kirim kredensial akun uji tersebut jika Anda ingin saya lanjutkan tes end-to-end; saya tidak akan menuliskannya ke file konfigurasi.

> Tomcat123!

<details><summary>1 previous message</summary>

> Saya gunakan kredensial itu hanya untuk satu request uji ke Tomcat Manager dan memeriksa log LDAP; password tidak akan disimpan atau ditulis ke konfigurasi.
</details>

Tes end-to-end berhasil: **HTTP 200** untuk Tomcat Manager menggunakan user LDAP `edkas07`.

Log OpenLDAP mengonfirmasi:

- bind user berhasil;
- pencarian `ou=groups,dc=lab,dc=local` berhasil;
- satu role ditemukan: `manager-gui`.

Tomcat sekarang autentikasi tanpa `connectionName` maupun password admin. Catatan kecil: OpenLDAP melaporkan atribut grup belum diindeks; fungsionalitas aman, tetapi indeks `uniqueMember` akan membantu performa saat grup/user bertambah.

> kamu bisa summarykan dan jelaskan terkait perbaikannya. dan metode yang digunakan apakah beresiko khususnya perubahan di ACL LDAP ?

Sudah beres dan teruji: user LDAP `edkas07` berhasil masuk ke Tomcat Manager dengan HTTP 200, mendapat role `manager-gui`, tanpa `connectionName` atau password admin pada `server.xml`.

Perbaikannya:

| Area | Sebelum | Sesudah |
|---|---|---|
| Autentikasi | Tomcat bind memakai `cn=admin,...` | Tomcat bind memakai DN user yang login |
| Password admin | Tersimpan di `server.xml` | Dihapus |
| Role LDAP | User tidak dapat mencari grup | ACL memberi user terautentikasi akses baca grup |
| Uji hasil | Gagal di `ou=groups` | Role `manager-gui` ditemukan dan login berhasil |

Metodenya adalah direct bind:

1. User memasukkan username/password ke Tomcat.
2. Tomcat membentuk DN `uid=<username>,ou=users,...`.
3. Tomcat bind ke OpenLDAP memakai password user tersebut.
4. Setelah bind sukses, Tomcat mencari grup user memakai `uniqueMember`.
5. ACL LDAP mengizinkan user yang telah terautentikasi melakukan pencarian tersebut.

Risiko ACL yang ditambahkan saat ini: semua user LDAP yang valid dapat membaca entry grup berikut nilai `uniqueMember`, `member`, dan `memberUid`. Artinya mereka dapat melihat keanggotaan grup—misalnya siapa yang berada dalam grup admin. ACL ini tidak memberi hak ubah; hanya read-only, tetapi visibilitas membership tetap bertambah.

Untuk lingkungan perusahaan, saya sarankan memperketatnya:

- Beri `read` hanya untuk `entry` dan `cn`, karena Tomcat hanya perlu menerima nama role.
- Beri hak `search`—bukan `read`—pada atribut membership seperti `uniqueMember`, agar Tomcat dapat mencocokkan filter tanpa mengembalikan daftar anggota grup.
- Jika hanya menggunakan `groupOfUniqueNames`, sederhanakan filter menjadi:

```xml
roleSearch="(uniqueMember={0})"
```

Risiko terbesar yang tersisa adalah `ldap://openldap:389`: password user dikirim tanpa TLS. Meskipun jaringan Podman internal, untuk produksi sebaiknya gunakan LDAPS atau StartTLS dan truststore Java yang memercayai CA LDAP.
