#!/bin/bash

# Veri dosyaları
KULLANICI_DOSYASI="kullanici.csv"
DEPO_DOSYASI="depo.csv"
LOG_DOSYASI="log.csv"

# Genel değişkenler
GIRIS_HAKKI=3
KULLANICI=""
#$kalan_hak -gt 0
# Kullanıcıyı doğrulama fonksiyonu
function kullanici_dogrula {
    local kalan_hak=$GIRIS_HAKKI
    while [[ 1 ]]; do
        KULLANICI=$(zenity --entry --title="Giriş" --text="Kullanıcı Adınızı Girin:")
        SIFRE=$(zenity --password --title="Giriş" --text="Şifrenizi Girin:")

        local kayit=$(grep "^$KULLANICI,$SIFRE" $KULLANICI_DOSYASI)
        if [[ ! -z $kayit ]]; then
            local rol=$(echo $kayit | cut -d',' -f3)
            local durum=$(echo $kayit | cut -d',' -f4)
            if [[ $durum == "kilitli" ]]; then
                zenity --error --title="Hesap Kilitli" --text="Bu hesap kilitlenmiştir. Yönetici ile iletişime geçin."
                continue
            fi
            echo "$rol"
            return 0
        else
            ((kalan_hak--))
            echo "$(date),$KULLANICI,Hatalı Giriş" >> $LOG_DOSYASI
            if [[ $kalan_hak -eq 0 ]]; then
                sed -i "s/^$KULLANICI,.*/&,kilitli/" $KULLANICI_DOSYASI
                zenity --error --title="Hesap Kilitli" --text="Üç başarısız giriş denemesi. Hesap kilitlenmiştir."
		echo "$(date),$KULLANICI,kullanici kilitlendi" >> $LOG_DOSYASI
	
		continue               
            fi
            zenity --error --title="Hatalı Giriş" --text="Kullanıcı adı veya şifre yanlış. Kalan deneme: $kalan_hak"
        fi
    done
}

# Ana Menü
function ana_menu {
    local rol=$1
    while true; do
        local secim=$(zenity --list --title="Ana Menü" --width=600 --height=400 --column="İşlem" "Ürün Ekle" "Ürün Listele" "Ürün Güncelle" "Ürün Sil" "Rapor Al" "Kullanıcı Yönetimi" "Program Yönetimi" "Çıkış") 
        case $secim in
            "Ürün Ekle")
                if [[ $rol == "yonetici" ]]; then urun_ekle; else yetki_uyarisi ; fi ;;
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
            "Program Yönetimi")
                if [[ $rol == "yonetici" ]]; then program_yonetimi; else yetki_uyarisi; fi ;;
            
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
	echo "$(date),user,Yetkisiz Giriş Denmesi" >> $LOG_DOSYASI
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
		echo "$(date),admin,Aynı ürün mevcut" >> $LOG_DOSYASI
            continue
        fi

        # Stok miktarı alma
        local stok=$(zenity --entry --title="Ürün Ekle" --text="Stok Miktarı:")
        if [[ ! $stok =~ ^[0-9]+$ ]]; then
            zenity --error --title="Hatalı Giriş" --text="Stok miktarı yalnızca pozitif bir sayı olabilir. Lütfen tekrar deneyiniz."
        echo "$(date),admin,stok miktarı na sayi dışında girdi" >> $LOG_DOSYASI    
	continue
        fi

        # Birim fiyat alma
        local fiyat=$(zenity --entry --title="Ürün Ekle" --text="Birim Fiyatı:")
        if [[ ! $fiyat =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
            zenity --error --title="Hatalı Giriş" --text="Birim fiyat yalnızca pozitif bir sayı olabilir. Lütfen tekrar deneyiniz."
           echo "$(date),admin,birim fiyat a sayı dışında girdi" >> $LOG_DOSYASI 
	continue
        fi

        # Kategori alma
        local kategori=$(zenity --entry --title="Ürün Ekle" --text="Kategori:")
        if [[ -z $kategori || $kategori =~ [[:space:]] ]]; then
            zenity --error --title="Hatalı Giriş" --text="Kategori adı boş veya boşluk içeremez. Lütfen geçerli bir kategori giriniz."
            echo "$(date),admin,kategoriye boşluk girildi" >> $LOG_DOSYASI
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
        echo "$(date),admin,depoda olmayan bir ürün girişi" >> $LOG_DOSYASI
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


#Rapor Al Fonksiyonu
function rapor_al {
    # Kullanıcıya rapor türü seçeneklerini sun
    local secim=$(zenity --list --title="Rapor Al" --column="Rapor Türü" \
        "Stokta Azalan Ürünler" \
        "En Yüksek Stok Miktarına Sahip Ürünler" \
        "Toplam Mevcut Stok Adedi" \
        "En Son Eklenen Ürün")
    
    if [[ -z $secim ]]; then
        zenity --info --title="İşlem İptal Edildi" --text="Rapor alma işlemi iptal edildi."
        return
    fi

    case $secim in
        "Stokta Azalan Ürünler")
            # Kullanıcıdan eşik değeri al
            local esik=$(zenity --entry --title="Eşik Değeri" --text="Stokta azalan ürünler için eşik değerini giriniz:")
            if [[ -z $esik || ! $esik =~ ^[0-9]+$ ]]; then
                zenity --error --title="Hatalı Giriş" --text="Geçerli bir eşik değeri giriniz. (0 veya pozitif bir sayı)"
                return
            fi
            # Stokta azalan ürünleri listele
            local sonuc=$(awk -F',' -v esik="$esik" '$3 < esik {print "\n\nÜrün Adı: "$2", Stok: "$3", Fiyat: "$4", Kategori: "$5}' "$DEPO_DOSYASI")
            if [[ -z $sonuc ]]; then
                zenity --info --title="Rapor Sonucu" --text="Eşik değerinin altında stokta azalan ürün bulunmamaktadır."
            else
                zenity --text-info --title="Stokta Azalan Ürünler" --filename=<(echo "$sonuc")
            fi
            ;;
        
        "En Yüksek Stok Miktarına Sahip Ürünler")
            # Kullanıcıdan eşik değeri al
            local esik=$(zenity --entry --title="Eşik Değeri" --text="En yüksek stok miktarına sahip ürünler için eşik değerini giriniz:")
            if [[ -z $esik || ! $esik =~ ^[0-9]+$ ]]; then
                zenity --error --title="Hatalı Giriş" --text="Geçerli bir eşik değeri giriniz. (0 veya pozitif bir sayı)"
                return
            fi
            # En yüksek stok miktarına sahip ürünleri listele
            local sonuc=$(awk -F',' -v esik="$esik" '$3 >= esik {print "\n\n Ürün Adı: "$2"\n Stok: "$3"\n Fiyat: "$4"\n Kategori: "$5}' "$DEPO_DOSYASI")
            if [[ -z $sonuc ]]; then
                zenity --info --title="Rapor Sonucu" --text="Eşik değerini karşılayan ürün bulunmamaktadır."
            else
                zenity --text-info --title="En Yüksek Stok Miktarına Sahip Ürünler" --filename=<(echo "$sonuc")
            fi
            ;;
        
        "Toplam Mevcut Stok Adedi")
            # Toplam stok adedini hesapla
            local toplam_stok=$(awk -F',' '{s+=$3} END {print s}' "$DEPO_DOSYASI")
            zenity --info --title="Toplam Mevcut Stok" --text="Toplam mevcut stok adedi: $toplam_stok"
            ;;
        
        "En Son Eklenen Ürün")
            # En son eklenen ürünü bul
            local son_urun=$(tail -n 1 "$DEPO_DOSYASI")
            if [[ -z $son_urun ]]; then
                zenity --info --title="Rapor Sonucu" --text="Henüz eklenmiş bir ürün bulunmamaktadır."
            else
                local urun_bilgi=$(echo "$son_urun" | awk -F',' '{print "Ürün No: "$1"\nÜrün Adı: "$2"\nStok: "$3"\nFiyat: "$4"\nKategori: "$5}')
                zenity --info --title="En Son Eklenen Ürün" --text="$urun_bilgi"
            fi
            ;;
    esac
}

#Kullanıcı Yönetimi Fonksiyonu
function kullanici_yonetimi {
    # Operatöre seçenekleri sun
    local secim=$(zenity --list --title="Kullanıcı Yönetimi" --column="İşlem Seçenekleri" \
        "Yeni Kullanıcı Ekle" \
        "Kullanıcıları Listele" \
        "Kullanıcı Güncelle" \
        "Kullanıcı Sil")

    if [[ -z $secim ]]; then
        zenity --info --title="İşlem İptal Edildi" --text="Kullanıcı yönetimi işlemi iptal edildi."
        return
    fi

    case $secim in
        "Yeni Kullanıcı Ekle")
            # Yeni kullanıcı eklemek için gerekli bilgileri al
            #local yeni_no=$(awk -F',' 'END {print $1+1}' "$KULLANICI_DOSYASI") # No değeri otomatik artacak
            local adi=$(zenity --entry --title="Yeni Kullanıcı Ekle" --text="Kullanici Adi:")
            local sifre=$(zenity --entry --title="Yeni Kullanıcı Ekle" --text="Şifre:")
            local rol=$(zenity --list --title="Kullanıcı Rolü" --column="Rol" "yonetici" "kullanici")
            local durum=$(zenity --list --title="Yeni Kullanıcı Ekle" --column="Durum" "aktif" "pasif")
            #local md5_parola=$(echo -n "$parola" | md5sum | awk '{print $1}')  # MD5 parolası al

            # Kullanıcı bilgilerini dosyaya ekle
            echo "$adi,$sifre,$rol,$durum" >> "$KULLANICI_DOSYASI"
            zenity --info --title="Başarılı" --text="Kullanıcı başarıyla eklendi."
            ;;

        "Kullanıcıları Listele")
            # Kullanıcıları listele
            local kullanici_listesi=$(cat "$KULLANICI_DOSYASI" | awk -F',' '{print  "\n\nKullanici Adi: "$1"\n Sifre: "$2"\n Rol: "$3"\n Durum: "$4}')
            if [[ -z $kullanici_listesi ]]; then
                zenity --info --title="Kullanıcılar" --text="Henüz kayıtlı bir kullanıcı bulunmamaktadır."
            else
                zenity --text-info --title="Kullanıcılar" --filename=<(echo "$kullanici_listesi")
            fi
            ;;

        "Kullanıcı Güncelle")
            # Güncelleme işlemi için kullanıcı adını al
            local kullanici_adi=$(zenity --entry --title="Kullanıcı Güncelle" --text="Güncellemek istediğiniz kullanıcının adını giriniz:")
            local kullanici=$(grep -i "$kullanici_adi" "$KULLANICI_DOSYASI")

            if [[ -z $kullanici ]]; then
                zenity --error --title="Kullanıcı Bulunamadı" --text="Bu adla bir kullanıcı bulunamadı."
                return
            fi

            # Kullanıcı bilgilerini güncelle
            local kullaniciAdi=$(echo "$kullanici" | cut -d',' -f1)
            local sifreA=$(echo "$kullanici" | cut -d',' -f2)
            local rol=$(echo "$kullanici" | cut -d',' -f3)

            local yeni_adi=$(zenity --entry --title="Kullanıcı Güncelle" --text="Yeni Kullanıcı Adı: ")
            local yeni_sifre=$(zenity --entry --title="Kullanıcı Güncelle" --text="Yeni Sifre:")
            local yeni_rol=$(zenity --list --title="Kullanıcı Rolü" --column="Rol" "yonetici" "kullanici")
            local yeni_durum=$(zenity --list --title="Kullanıcı Güncelle" --column="Yeni Durum" "aktif" "pasif")
            
            # Güncellenmiş verileri dosyaya yaz
            awk -F',' -v kullanici_adi="$yeni_adi" -v sifre="$yeni_sifre" -v Rol="$yeni_rol" -v Durum="$yeni_durum" \
                'BEGIN {OFS=","} $1 == kullanici_adi {$2=sifre; $3=Rol; $4=Durum;} {print $0}' "$KULLANICI_DOSYASI" > temp.csv && mv temp.csv "$KULLANICI_DOSYASI"
            zenity --info --title="Başarılı" --text="Kullanıcı başarıyla güncellendi."
            ;;

        "Kullanıcı Sil")
            # Kullanıcıyı silmek için adı alın
            local kullanici_adi=$(zenity --entry --title="Kullanıcı Sil" --text="Silmek istediğiniz kullanıcının adını giriniz:")
            local kullanici=$(grep -i "$kullanici_adi" "$KULLANICI_DOSYASI")

            if [[ -z $kullanici ]]; then
                zenity --error --title="Kullanıcı Bulunamadı" --text="Bu adla bir kullanıcı bulunamadı."
		echo "$(date),admin,mevcut olmayan bir kullanici silme" >> $LOG_DOSYASI
                return
            fi

            # Teyit kutusu ile silme işlemi
            local teyit=$(zenity --question --title="Kullanıcı Sil" --text="$kullanici_adi kullanıcısını silmek istediğinize emin misiniz?" --ok-label="Evet" --cancel-label="Hayır")
            if [[ $? -eq 0 ]]; then
                # Kullanıcıyı sil
                awk -F',' -v adi="$kullanici_adi" '$1 != adi' "$KULLANICI_DOSYASI" > temp.csv && mv temp.csv "$KULLANICI_DOSYASI"
                zenity --info --title="Başarılı" --text="Kullanıcı başarıyla silindi."
            else
                zenity --info --title="İşlem İptal Edildi" --text="Kullanıcı silme işlemi iptal edildi."
            fi
            ;;
    esac
}


#Program Yönetimi Fonksiyonu
function program_yonetimi {
    # Seçenekleri kullanıcıya sun
    local secim=$(zenity --list --title="Program Yönetimi" --column="İşlem Seçenekleri" \
        "Diskteki Alanı Göster" \
        "Diske Yedekle" \
        "Hata Kayıtlarını Göster")

    if [[ -z $secim ]]; then
        zenity --info --title="İşlem İptal Edildi" --text="Program yönetimi işlemi iptal edildi."
        return
    fi

    case $secim in
        "Diskteki Alanı Göster")
            # İlgili dosyaların disk boyutunu al ve bilgilendirme kutusunda göster
            local proje_size=$(du -sh "proje.sh" | awk '{print $1}')
            local depo_size=$(du -sh "$DEPO_DOSYASI" | awk '{print $1}')
            local kullanici_size=$(du -sh "$KULLANICI_DOSYASI" | awk '{print $1}')
            local log_size=$(du -sh "$LOG_DOSYASI" | awk '{print $1}')
            
            zenity --info --title="Diskteki Alan Kullanımı" --text="Dosyaların Diskteki Alan Kullanımı:\n\n\
proje.sh: $proje_size\n\
$DEPO_DOSYASI: $depo_size\n\
$KULLANICI_DOSYASI: $kullanici_size\n\
$LOG_DOSYASI: $log_size"
            ;;

       "Diske Yedekle")
    # Yedekleme dizini oluştur
    local yedek_dir="yedekler"
    mkdir -p "$yedek_dir"
    
    # Progress bar başlat
    (
        echo "2" # Yedekleme işlemi başlıyor
        sleep 1
        echo "10" # Yedekleme işlemi başlıyor
        sleep 1
        echo "25" # Yedekleme işlemi başlıyor
        sleep 1
        
        # Dosyaları yedekle
        cp "$DEPO_DOSYASI" "$yedek_dir/depo_$(date +%F_%T).csv"
        echo "50" # Depo dosyası yedeklendi
        sleep 1
	echo "65" # Yedekleme işlemi başlıyor
        sleep 1
        echo "85" # Yedekleme işlemi başlıyor
        sleep 1
        
        
        cp "$KULLANICI_DOSYASI" "$yedek_dir/kullanici_$(date +%F_%T).csv"
        echo "%100 yedekleme tatamlandı..." # Kullanıcı dosyası yedeklendi
    ) | zenity --progress --title="Diske Yedekleme" --text="Yedekleme işlemi devam ediyor..." --percentage=0 --auto-close
    
    # Yedekleme tamamlandıktan sonra bilgi kutusu göster
    zenity --info --title="Başarılı" --text="Dosyalar başarıyla yedeklendi. Yedekleme dizini: $yedek_dir"
    ;;

        "Hata Kayıtlarını Göster")
            # log.csv dosyasını aç
            if [[ -s "$LOG_DOSYASI" ]]; then
                zenity --text-info --title="Hata Kayıtları" --filename="$LOG_DOSYASI"
            else
                zenity --info --title="Hata Kayıtları" --text="Hata kaydı bulunmamaktadır."
            fi
            ;;
    esac
}



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
