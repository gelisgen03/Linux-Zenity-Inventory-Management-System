#!/bin/bash

# Veri dosyaları
KULLANICI_DOSYASI="kullanici.csv"
DEPO_DOSYASI="depo.csv"
LOG_DOSYASI="log.csv"

# Genel değişkenler
GIRIS_HAKKI=3
KULLANICI=""

# Kullanıcıyı doğrulama fonksiyonu
function kullanici_dogrula {
    local kalan_hak=$GIRIS_HAKKI
    while [[ $kalan_hak -gt 0 ]]; do
        KULLANICI=$(zenity --entry --title="Giriş" --text="Kullanıcı Adınızı Girin:")
        SIFRE=$(zenity --password --title="Giriş" --text="Şifrenizi Girin:")

        local kayit=$(grep "^$KULLANICI,$SIFRE" $KULLANICI_DOSYASI)
        if [[ ! -z $kayit ]]; then
            local rol=$(echo $kayit | cut -d',' -f3)
            local durum=$(echo $kayit | cut -d',' -f4)
            if [[ $durum == "kilitli" ]]; then
                zenity --error --title="Hesap Kilitli" --text="Bu hesap kilitlenmiştir. Yönetici ile iletişime geçin."
                exit 1
            fi
            echo "$rol"
            return 0
        else
            ((kalan_hak--))
            echo "$(date),$KULLANICI,Hatalı Giriş" >> $LOG_DOSYASI
            if [[ $kalan_hak -eq 0 ]]; then
                sed -i "s/^$KULLANICI,.*/&,kilitli/" $KULLANICI_DOSYASI
                zenity --error --title="Hesap Kilitli" --text="Üç başarısız giriş denemesi. Hesap kilitlenmiştir."
                exit 1
            fi
            zenity --error --title="Hatalı Giriş" --text="Kullanıcı adı veya şifre yanlış. Kalan deneme: $kalan_hak"
        fi
    done
}

# Ana Menü
function ana_menu {
    local rol=$1
    while true; do
        local secim=$(zenity --list --title="Ana Menü" --width=600 --height=400 --column="İşlem" "Ürün Ekle" "Ürün Listele" "Ürün Güncelle" "Ürün Sil" "Rapor Al" "Kullanıcı Yönetimi" "Çıkış")
        
        case $secim in
            "Ürün Ekle")
                if [[ $rol == "yonetici" ]]; then urun_ekle; else yetki_uyarisi; fi ;;
            "Ürün Listele")
                urun_listele ;;
            "Ürün Güncelle")
                if [[ $rol == "yonetici" ]]; then urun_guncelle; else yetki_uyarisi; fi ;;
            "Ürün Sil")
                if [[ $rol == "yonetici" ]]; then urun_sil; else yetki_uyarisi; fi ;;
            "Rapor Al")
                rapor_al ;;
            "Kullanıcı Yönetimi")
                if [[ $rol == "yonetici" ]]; then kullanici_yonetimi; else yetki_uyarisi; fi ;;
            "Çıkış")
                zenity --question --title="Çıkış" --text="Çıkmak istediğinize emin misiniz?"
                if [[ $? -eq 0 ]]; then exit 0; fi ;;
            *)
                zenity --error --title="Hata" --text="Geçersiz seçim." ;;
        esac
    done
}

# Yetki Uyarısı
function yetki_uyarisi {
    zenity --error --title="Yetki Hatası" --text="Bu işlemi gerçekleştirme yetkiniz yok."
}

# Ürün Ekleme Fonksiyonu
function urun_ekle {
    # En yüksek ürün numarasını bul
    local max_urun_no=0
    if [[ -s $DEPO_DOSYASI ]]; then
        max_urun_no=$(awk -F',' '{if ($1+0 > max) max=$1} END {print max}' $DEPO_DOSYASI)
    fi
    local urun_no=$((max_urun_no + 1))

    while true; do
        # Ürün adı alma
        local urun_adi=$(zenity --entry --title="Ürün Ekle" --text="Ürün Adı:")
        if [[ -z $urun_adi || $urun_adi =~ [[:space:]] ]]; then
            zenity --error --title="Hatalı Giriş" --text="Ürün adı boş veya boşluk içeremez. Lütfen geçerli bir ad giriniz."
            continue
        fi

        # Aynı isimde ürün kontrolü
        if grep -q "^.*,$urun_adi,.*$" "$DEPO_DOSYASI"; then
            zenity --error --title="Hatalı Giriş" --text="Bu ürün adıyla başka bir kayıt bulunmaktadır. Lütfen farklı bir ad giriniz."
            continue
        fi

        # Stok miktarı alma
        local stok=$(zenity --entry --title="Ürün Ekle" --text="Stok Miktarı:")
        if [[ ! $stok =~ ^[0-9]+$ ]]; then
            zenity --error --title="Hatalı Giriş" --text="Stok miktarı yalnızca pozitif bir sayı olabilir. Lütfen tekrar deneyiniz."
            continue
        fi

        # Birim fiyat alma
        local fiyat=$(zenity --entry --title="Ürün Ekle" --text="Birim Fiyatı:")
        if [[ ! $fiyat =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
            zenity --error --title="Hatalı Giriş" --text="Birim fiyat yalnızca pozitif bir sayı olabilir. Lütfen tekrar deneyiniz."
            continue
        fi

        # Kategori alma
        local kategori=$(zenity --entry --title="Ürün Ekle" --text="Kategori:")
        if [[ -z $kategori || $kategori =~ [[:space:]] ]]; then
            zenity --error --title="Hatalı Giriş" --text="Kategori adı boş veya boşluk içeremez. Lütfen geçerli bir kategori giriniz."
            continue
        fi

        # Tüm kontroller başarılıysa dosyaya yaz
        echo "$urun_no,$urun_adi,$stok,$fiyat,$kategori" >> $DEPO_DOSYASI
        zenity --info --title="Başarılı" --text="Ürün başarıyla eklendi. Ürün Numarası: $urun_no"
        break
    done
}



#Ürün Lİsteleme Fonksiyonu
function urun_listele {
    if [[ ! -s $DEPO_DOSYASI ]]; then
        zenity --info --title="Ürün Listeleme" --text="Depoda ürün bulunmamaktadır."
        return
    fi

    # Ürünleri formatlayarak bir metin haline getirme
    local urun_listesi=$(awk -F',' 'BEGIN { printf "%-10s %-20s %-10s %-10s %-15s\n", "Ürün No", "Ürün Adı", "Stok", "Fiyat", "Kategori" }
                                { printf "%-10s %-20s %-10s %-10s %-15s\n", $1, $2, $3, $4, $5 }' $DEPO_DOSYASI)

    # Zenity ile metni gösterme
    echo "$urun_listesi" | zenity --text-info --title="Ürün Listeleme" --width=600 --height=400

    return
}
#ürn Silme Fonksiyonu
function urun_sil {
    # Kullanıcıdan ürün adı al
    local urun_adi=$(zenity --entry --title="Ürün Sil" --text="Silmek istediğiniz ürünün adını giriniz:")
    if [[ -z $urun_adi ]]; then
        zenity --error --title="Hatalı Giriş" --text="Ürün adı boş bırakılamaz. Lütfen geçerli bir ad giriniz."
        return
    fi

    # Ürün kontrolü yap
    if ! grep -q "^.*,$urun_adi,.*$" "$DEPO_DOSYASI"; then
        zenity --error --title="Ürün Bulunamadı" --text="Girilen adla eşleşen bir ürün bulunamadı. Lütfen tekrar deneyiniz."
        return
    fi

    # Teyit kutusu
    if ! zenity --question --title="Ürün Silme Onayı" --text="$urun_adi ürününü silmek istediğinize emin misiniz?"; then
        zenity --info --title="İşlem İptal Edildi" --text="Ürün silme işlemi iptal edildi."
        return
    fi

    # Ürünü dosyadan sil
    grep -v "^.*,$urun_adi,.*$" "$DEPO_DOSYASI" > temp.csv && mv temp.csv "$DEPO_DOSYASI"

    # Başarı mesajı
    zenity --info --title="Başarılı" --text="$urun_adi başarıyla silindi."
}

#Ürün Güncelleme Fonksiyonu
function urun_guncelle {
    # Kullanıcıdan ürün adı al
    local urun_adi=$(zenity --entry --title="Ürün Güncelle" --text="Güncellemek istediğiniz ürünün adını giriniz:")
    if [[ -z $urun_adi ]]; then
        zenity --error --title="Hatalı Giriş" --text="Ürün adı boş bırakılamaz. Lütfen geçerli bir ad giriniz."
        return
    fi

    # Ürünü kontrol et ve satırı al
    local urun_satiri=$(grep "^.*,$urun_adi,.*$" "$DEPO_DOSYASI")
    if [[ -z $urun_satiri ]]; then
        zenity --error --title="Ürün Bulunamadı" --text="Girilen adla eşleşen bir ürün bulunamadı. Lütfen tekrar deneyiniz."
        return
    fi

    # Mevcut ürün bilgilerini ayır
    local urun_no=$(echo "$urun_satiri" | cut -d',' -f1)
    local stok=$(echo "$urun_satiri" | cut -d',' -f3)
    local fiyat=$(echo "$urun_satiri" | cut -d',' -f4)

    # Güncelleme seçimi
    local secim=$(zenity --list --title="Güncelleme Seçimi" --column="Seçim" "Stok Güncelle" "Fiyat Güncelle")
    if [[ -z $secim ]]; then
        zenity --info --title="İşlem İptal Edildi" --text="Ürün güncelleme işlemi iptal edildi."
        return
    fi

    # Güncellemeyi yap
    if [[ $secim == "Stok Güncelle" ]]; then
        local yeni_stok=$(zenity --entry --title="Stok Güncelle" --text="Mevcut stok: $stok\nYeni stok miktarını giriniz (0 veya pozitif bir sayı):")
        if [[ -z $yeni_stok || ! $yeni_stok =~ ^[0-9]+$ ]]; then
            zenity --error --title="Hatalı Giriş" --text="Geçerli bir stok miktarı giriniz. (0 veya pozitif bir sayı)"
            return
        fi
        stok=$yeni_stok
    elif [[ $secim == "Fiyat Güncelle" ]]; then
        local yeni_fiyat=$(zenity --entry --title="Fiyat Güncelle" --text="Mevcut fiyat: $fiyat\nYeni birim fiyatını giriniz (0 veya pozitif bir sayı):")
        if [[ -z $yeni_fiyat || ! $yeni_fiyat =~ ^[0-9]+([.][0-9]+)?$ ]]; then
            zenity --error --title="Hatalı Giriş" --text="Geçerli bir birim fiyatı giriniz. (0 veya pozitif bir sayı)"
            return
        fi
        fiyat=$yeni_fiyat
    fi

    # Güncellenmiş satırı oluştur ve dosyaya yaz
    local yeni_satir="$urun_no,$urun_adi,$stok,$fiyat,$(echo "$urun_satiri" | cut -d',' -f5)"
    grep -v "^.*,$urun_adi,.*$" "$DEPO_DOSYASI" > temp.csv
    echo "$yeni_satir" >> temp.csv
    mv temp.csv "$DEPO_DOSYASI"

    # Başarı mesajı
    zenity --info --title="Başarılı" --text="$urun_adi başarıyla güncellendi."
}


# Diğer işlemler (Ürün Listele, Ürün Güncelle, Ürün Sil, Rapor Al, Kullanıcı Yönetimi)
# Her bir işlem için benzer fonksiyonlar eklenebilir.

# Başlangıç
if [[ ! -f $KULLANICI_DOSYASI ]]; then
    echo "admin,admin123,yonetici,aktif" > $KULLANICI_DOSYASI
fi
if [[ ! -f $DEPO_DOSYASI ]]; then
    touch $DEPO_DOSYASI
fi
if [[ ! -f $LOG_DOSYASI ]]; then
    touch $LOG_DOSYASI
fi

ROL=$(kullanici_dogrula)
ana_menu $ROL
