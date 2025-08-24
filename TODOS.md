# Todos

## Manual

- [ ] Viết cho tôi file shell script
  - [ ] Tạo SSH key
  - [ ] In log ra màn hình với các chế độ màu sắc
  - [ ] In log ra màn hình với các chế độ màu sắc

  

## Q & A

- Công cụ log viewer trên Linux
- Cài đặt:
  - httpie
  - dust
- Xem bitnami
    - airflow

## AI
- aws cli script dùng bin log thay vì tự viết hàm, tránh duplicate
- Không cần fallback vì file này chắc chắn có source "/opt/laragis/scripts/liblog.sh"

- Nếu pkg-core.sh, pkg-essential.sh, pkg-dev.sh, pkg-modern.sh không cài bằng dnf được thì dùng file trong folder features


- Cài gum (https://github.com/charmbracelet/gum/releases/tag/v0.16.2) - dùng file resources/prebuildfs/opt/laragis/features/gum.sh, getoptions (https://github.com/ko1nksm/getoptions/releases) - dùng resources/prebuildfs/opt/laragis/features/getoptions.sh, Dùng file lock như này /opt/laragis/features/gum.installed, echo metadata vào file lock, hàm tạo metadata cho lock file thì dùng ở resources/prebuildfs/opt/laragis/lib/lib-metadata.sh
- Chạy task build để kiểm tra
------
- getoptions.shm gum.sh viết tránh duplicate, cần thì tạo thư viện hàm trong resources/prebuildfs/opt/laragis/lib, log thì sử dụng từ resources/prebuildfs/opt/laragis/lib/lib-log.sh
- các hàm trong resources/prebuildfs/opt/laragis/lib/lib-metadata.sh, cần tách ra file riêng không, đặt tên hàm nên dùng prefix (metadata_) thay vì create_binary_metadata, create_source_metadata,.. để dễ gom nhóm hơn
- installation cần tách ra thành lib không
------
- dùng indent 2 shell scripts
- fix lỗi task build không cài được gum, getoptions, không sử dụng bin log install-deps
-----
- Dùng vậy COPY --exclude=**/setup --exclude=**/tools resources/prebuildfs/ / thì nó bị mất cache features files, các file features nên copy từng file
- Đừng cài log install-deps
- Chạy feature gum cài đặt mà không cần dùng log install-deps vì tôi muốn độc lập
