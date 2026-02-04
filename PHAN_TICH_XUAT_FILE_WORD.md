# PHÂN TÍCH CHỨC NĂNG XUẤT FILE WORD

## 📋 Tổng Quan

Project BHLD (Bảo Hộ Lao Động) sử dụng **TinyButStrong Template Engine** kết hợp với **OpenTBS Plugin** để xuất file Word (.docx). Đây là giải pháp mạnh mẽ cho việc tạo báo cáo, chứng từ động từ template Word.

---

## 🔧 Công Nghệ & Thư Viện

### 1. TinyButStrong (TBS)
- **Version**: 3.11.0 cho PHP 5 và 7
- **File**: `tbs_class.php`
- **Tác dụng**: Template engine chính để merge dữ liệu vào template
- **License**: LGPL-3.0
- **Website**: http://www.tinybutstrong.com

### 2. OpenTBS Plugin  
- **Version**: 1.10.0
- **File**: `tbs_plugin_opentbs.php`
- **Tác dụng**: Plugin mở rộng TBS để xử lý file OpenXML (docx, xlsx, pptx)
- **License**: LGPL-3.0
- **Đặc điểm**:
  - Mở và đọc file ZIP (docx là file ZIP)
  - Đọc central directory
  - Truy xuất nội dung file không nén trong ZIP
  - Hỗ trợ MS Word, Excel, PowerPoint

---

## 📂 Cấu Trúc File

### Các File PHP Xuất Word Chính

1. **in_giay_di_bien.php** - In giấy đi biên
2. **in_chung_tu_theo_thang.php** - In chứng từ theo tháng
3. **in_chung_tu_tong_thang.php** - In tổng chứng từ tháng

### Template Word (.docx)

1. `giaydibien2.docx` - Template giấy đi biên
2. `chung_tu_chua_nhan_3.docx` - Template chứng từ chưa nhận
3. `thongke_tong_danhan.docx` - Template thống kê tổng đã nhận
4. `chung_tu_chua_nhan.docx` - Template khác
5. `chung_tu_chua_nhan_2.docx` - Template khác

---

## 🎯 Quy Trình Xuất File Word

### Bước 1: Khởi Tạo TBS và Plugin

```php
// Include thư viện
include_once('tbs_class.php');
include_once('tbs_plugin_opentbs.php');

// Set timezone (tránh lỗi PHP)
if (version_compare(PHP_VERSION,'5.1.0')>=0) {
    if (ini_get('date.timezone')=='') {
        date_default_timezone_set('UTC');
    }
}

// Khởi tạo TBS
$TBS = new \clsTinyButStrong();

// Cài đặt plugin OpenTBS
$TBS->Plugin(TBS_INSTALL, OPENTBS_PLUGIN);
```

### Bước 2: Load Template Word

```php
$template = 'giaydibien2.docx';
$TBS->LoadTemplate($template, OPENTBS_ALREADY_UTF8);
```

**Tham số quan trọng**:
- `OPENTBS_ALREADY_UTF8`: Báo cho TBS biết file đã ở dạng UTF-8

### Bước 3: Lấy Dữ Liệu Từ Database

```php
// Connect database (sử dụng mysqli)
require_once "db.php";

// Query dữ liệu
$mySql = "SELECT nhan_vien.danh_so, nhan_vien.ten_nhan_vien, 
          bo_phan.ten_bo_phan, giay_di_bien.ngay_di, 
          giay_di_bien.nhiem_vu, gian_khoan.ten_gian_khoan,
          giay_di_bien.ngay_cap, giay_di_bien.so_cong_lenh
          FROM giay_di_bien 
          INNER JOIN nhan_vien ON nhan_vien.nhan_vien_id = giay_di_bien.nhan_vien_id 
          INNER JOIN bo_phan ON nhan_vien.bo_phan_id = bo_phan.bo_phan_id 
          INNER JOIN gian_khoan ON giay_di_bien.gian_id = gian_khoan.gian_khoan_id
          WHERE giay_di_bien_id IN (".$id.")";

// Chuẩn bị mảng dữ liệu
$data = array();

if ($result = $conn->query($mySql)) {
    while ($row = mysqli_fetch_array($result)) {
        $data[] = array(
            'danh_so' => $row["danh_so"],
            'tennhanvien' => $row["ten_nhan_vien"],
            'ngay_di' => $row["ngay_di"],
            'ten_bo_phan' => $row["ten_bo_phan"],
            'nhiem_vu' => $row["nhiem_vu"],
            'ten_gian_khoan' => $row["ten_gian_khoan"],
            'soyc' => $row["so_cong_lenh"],
            'ngay_cap' => $row["ngay_cap"]
        );
    }
    $result->free_result();
}

$conn->close();
```

### Bước 4: Merge Dữ Liệu Vào Template

#### 4.1. Merge Block (Lặp dữ liệu)

```php
// Merge block 'c' với array $data
$TBS->MergeBlock('c', $data);

// Hoặc merge block lồng nhau
$TBS->MergeBlock('main', $data);
```

**Trong template Word**:
- Đặt placeholder: `[c.tennhanvien]`, `[c.ngay_di]`, `[c.nhiem_vu]`
- Block bắt đầu: `[c;block=tr]` (cho table row)
- Block kết thúc: tự động detect

#### 4.2. Merge Biến Đơn (Global Variables)

```php
// Khai báo biến global
global $showngay, $showngayin, $total;

$showngay = "Tháng 08-2020";
$showngayin = "01/08/2020";
$total = 1500;

// Trong template Word, dùng: [showngay], [showngayin], [total]
```

### Bước 5: Xuất File

#### 5.1. Download (Mặc định)

```php
$output_file_name = str_replace('.', '_'.date('Y-m-d').'.', $template);

// Xuất file để download
$TBS->Show(OPENTBS_DOWNLOAD, $output_file_name);
exit();
```

#### 5.2. Lưu File Trên Server

```php
// Xuất file lưu trên server
$TBS->Show(OPENTBS_FILE, $output_file_name);
exit("File [$output_file_name] has been created.");
```

---

## 🔍 Các Kỹ Thuật Nâng Cao

### 1. Merge Block Lồng Nhau

```php
// Dữ liệu phân cấp: Phòng ban -> Nhân viên
$data = array(
    array(
        'name' => 'Xưởng Sửa Chữa',
        'spokenlg' => array(
            array('tennhanvien' => 'Nguyễn Văn A', 'giaybh' => 10),
            array('tennhanvien' => 'Trần Văn B', 'giaybh' => 5)
        )
    ),
    array(
        'name' => 'Phòng Kỹ Thuật', 
        'spokenlg' => array(
            array('tennhanvien' => 'Lê Văn C', 'giaybh' => 8)
        )
    )
);

$TBS->MergeBlock('main', $data);
```

**Template Word**:
```
[main;block=tbs:section]
Phòng: [main.name]

[main.spokenlg;block=tr]
[main.spokenlg.tennhanvien] - [main.spokenlg.giaybh]
[/main.spokenlg]

[/main]
```

### 2. Xử Lý Ngày Tháng

```php
// Nhận ngày từ GET parameter (format: dd/mm/yyyy)
$ngay = (isset($_GET['ngay'])) ? $_GET['ngay'] : '';
$ngay = trim(''.$ngay);

// Chuyển đổi format
$old_date = explode('/', $ngay);
$new_date = $old_date[2].'-'.$old_date[1].'-'.$old_date[0]; // yyyy-mm-dd

// Lấy ngày cuối tháng
$lastday = date('t', strtotime($new_date));
$new_date2 = $old_date[2].'-'.$old_date[1].'-'.$lastday;

// Format hiển thị
$showngay = "Tháng ".$old_date[1]."-".$old_date[2];
```

### 3. Tính Tổng & Aggregate

```php
// Group by và sum
$mySql = "SELECT manv, tennhanvien, 
          SUM(GiayBH) as GiayBH,
          SUM(MuBH) as MuBH,
          SUM(QuanAo) as QuanAo,
          SUM(Kinh) as Kinh
          FROM bhld_view_chungtu_chuanhan_final 
          WHERE mapb='".$pb."' 
          AND ngct<='".$new_date2."'
          GROUP BY manv";

// Tính tổng riêng
$mySql = "SELECT sum(sl) FROM bhld_view_chungtu_danhan_final
          WHERE month(ngnhan)=month('".$new_date2."') 
          AND year(ngnhan)=year('".$new_date2."')";
$MyResult = mysqli_query($conn, $mySql);
$row = mysqli_fetch_row($MyResult);
$total = $row[0];
```

### 4. Debug Mode

```php
// Debug XML hiện tại
$TBS->Plugin(OPENTBS_DEBUG_XML_CURRENT, true);

// Debug thông tin
if (isset($_POST['debug']) && ($_POST['debug']=='info')) {
    $TBS->Plugin(OPENTBS_DEBUG_INFO, true);
}

// Debug XML show
if (isset($_POST['debug']) && ($_POST['debug']=='show')) {
    $TBS->Plugin(OPENTBS_DEBUG_XML_SHOW);
}
```

---

## 📝 Cú Pháp Template Word

### 1. Biến Đơn

```
[ten_bien]
[showngay]
[total]
```

### 2. Block Lặp - Table Row

```
[block_name;block=tr]
[block_name.field1] | [block_name.field2] | [block_name.field3]
```

### 3. Block Lặp - Section

```
[block_name;block=tbs:section]
Nội dung...
[block_name.field]
[/block_name]
```

### 4. Format Số

```
[total;frm='0,0']  # Format: 1,234,567
[price;frm='0.00']  # Format: 1234.56
```

### 5. Format Ngày

```
[ngay;frm='dd/mm/yyyy']
[ngay;frm='yyyy-mm-dd']
```

### 6. Điều Kiện (If)

```
[block_name.field;if [block_name.count]>0]
```

---

## 🎨 Thiết Kế Template Word

### Bước 1: Tạo Template Thủ Công

1. Mở MS Word
2. Thiết kế layout mong muốn
3. Chèn placeholder: `[ten_bien]`
4. Với table, đặt block: `[data;block=tr]` ở hàng đầu tiên
5. Lưu dưới dạng `.docx`

### Bước 2: Table Structure

```
+--------------------------------------------------+
| [data;block=tr]                                  |
| [data.stt] | [data.name] | [data.quantity]      |
+--------------------------------------------------+
```

**Khi merge**:
- TBS sẽ lặp hàng này theo số lượng phần tử trong `$data`
- Tự động thêm hàng mới

### Bước 3: Nested Table (Block lồng)

```
[phongban;block=tbs:section]
Phòng: [phongban.name]

+---------------------------------------------+
| [phongban.nhanvien;block=tr]                |
| [phongban.nhanvien.ten] | [phongban.nhanvien.sl] |
+---------------------------------------------+

[/phongban]
```

---

## ⚙️ Class ExportWord trong phpfn.php

Project cũng có class `ExportWord` tích hợp sẵn (dòng 1049 trong `phpfn.php`):

```php
class ExportWord extends ExportBase
{
    // Export
    public function export()
    {
        global $ExportFileName;
        if (!Config("DEBUG") && ob_get_length())
            ob_end_clean();
        
        AddHeader('Set-Cookie', 'fileDownload=true; path=/');
        AddHeader('Content-Type', 'application/msword' . 
                 ((Config("PROJECT_CHARSET") != '') ? '; charset=' . 
                  Config("PROJECT_CHARSET") : ''));
        AddHeader('Content-Disposition', 'attachment; filename=' . 
                 $ExportFileName . '.doc');
        
        if (SameText(Config("PROJECT_CHARSET"), "utf-8"))
            Write("\xEF\xBB\xBF");
        
        Write($this->Text);
    }
}
```

**Cách dùng**:
- Tự động được gọi khi export từ PHPMaker list page
- Export HTML as Word (.doc format - old format)
- Không dùng template, chỉ export nội dung HTML table

**Config trong ewcfg.php** (dòng 474):
```php
"word" => "ExportWord",
```

---

## 🚀 Implement Sang Project Khác

### Bước 1: Copy File Thư Viện

```
tbs_class.php           -> Copy sang project mới
tbs_plugin_opentbs.php  -> Copy sang project mới
```

### Bước 2: Copy Template Word

```
*.docx  -> Copy các template sang folder mới
```

### Bước 3: Tạo File PHP Xuất Word

```php
<?php
// Bước 1: Include thư viện
require_once "db.php";  // Database connection
include_once('tbs_class.php');
include_once('tbs_plugin_opentbs.php');

// Set timezone
if (version_compare(PHP_VERSION,'5.1.0')>=0) {
    if (ini_get('date.timezone')=='') {
        date_default_timezone_set('UTC');
    }
}

// Bước 2: Khởi tạo TBS
$TBS = new \clsTinyButStrong();
$TBS->Plugin(TBS_INSTALL, OPENTBS_PLUGIN);

// Bước 3: Load template
$template = 'template.docx';
$TBS->LoadTemplate($template, OPENTBS_ALREADY_UTF8);

// Bước 4: Lấy dữ liệu
$data = array();
// ... query database ...

// Bước 5: Merge dữ liệu
$TBS->MergeBlock('block_name', $data);

// Bước 6: Xuất file
$output_file_name = str_replace('.', '_'.date('Y-m-d').'.', $template);
$TBS->Show(OPENTBS_DOWNLOAD, $output_file_name);
exit();
?>
```

### Bước 4: Tạo Link Download

```php
// Trong page list hoặc view
echo '<a href="export_word.php?id=123" target="_blank">
      <i class="fa fa-file-word-o"></i> Xuất Word
      </a>';
```

### Bước 5: Handle Parameters

```php
// Nhận parameters
$id = (isset($_GET['id'])) ? intval($_GET['id']) : 0;
$ngay = (isset($_GET['ngay'])) ? $_GET['ngay'] : '';
$thang = (isset($_GET['thang'])) ? intval($_GET['thang']) : date('m');
$nam = (isset($_GET['nam'])) ? intval($_GET['nam']) : date('Y');

// Validate
if ($id <= 0) {
    die("ID không hợp lệ");
}
```

---

## 📊 Các Trường Hợp Sử Dụng

### 1. Báo Cáo Đơn Giản

**Dữ liệu**: 1 bản ghi
**Template**: Chỉ dùng biến đơn
**Code**:
```php
global $tennhanvien, $ngay, $phongban;
$tennhanvien = "Nguyễn Văn A";
$ngay = "01/08/2020";
$phongban = "Phòng Kỹ Thuật";
// Không cần MergeBlock
```

### 2. Báo Cáo Danh Sách

**Dữ liệu**: Nhiều bản ghi
**Template**: Table với block=tr
**Code**:
```php
$data = array(
    array('stt' => 1, 'ten' => 'A', 'sl' => 10),
    array('stt' => 2, 'ten' => 'B', 'sl' => 20)
);
$TBS->MergeBlock('data', $data);
```

### 3. Báo Cáo Phân Cấp

**Dữ liệu**: Nhiều cấp (Phòng ban -> Nhân viên)
**Template**: Block lồng nhau
**Code**:
```php
$data = array(
    array(
        'tenphong' => 'Phòng A',
        'nhanvien' => array(
            array('ten' => 'NV1', 'sl' => 10),
            array('ten' => 'NV2', 'sl' => 20)
        )
    )
);
$TBS->MergeBlock('phong', $data);
```

---

## 🔒 Security & Best Practices

### 1. SQL Injection Prevention

```php
// BAD
$id = $_GET['id'];
$sql = "WHERE id = ".$id;

// GOOD
$id = intval($_GET['id']);
// hoặc dùng prepared statement

// GOOD với string
$id = mysqli_real_escape_string($conn, $_GET['id']);
```

### 2. Input Validation

```php
// Validate ngày
$ngay = trim(''.$_GET['ngay']);
if (!preg_match('/^\d{2}\/\d{2}\/\d{4}$/', $ngay)) {
    die("Format ngày không hợp lệ");
}

// Validate số
$id = intval($_GET['id']);
if ($id <= 0) {
    die("ID không hợp lệ");
}
```

### 3. Error Handling

```php
// Check database connection
if (!$conn) {
    die("Không thể kết nối database: " . mysqli_connect_error());
}

// Check query result
if (!$result = $conn->query($mySql)) {
    die("Query error: " . $conn->error);
}

// Check template exists
if (!file_exists($template)) {
    die("Template không tồn tại: " . $template);
}
```

### 4. Memory Management

```php
// Free result
if ($result) {
    $result->free_result();
}

// Close connection
$conn->close();

// Clean output buffer before export
if (!Config("DEBUG") && ob_get_length()) {
    ob_end_clean();
}
```

---

## 🐛 Troubleshooting

### Lỗi 1: File bị lỗi khi mở

**Nguyên nhân**: Output buffer có nội dung thừa
**Giải pháp**:
```php
ob_end_clean();  // Trước khi Show()
exit();          // Sau khi Show()
```

### Lỗi 2: Font tiếng Việt bị lỗi

**Nguyên nhân**: Encoding không đúng
**Giải pháp**:
```php
$TBS->LoadTemplate($template, OPENTBS_ALREADY_UTF8);
// Và database phải UTF-8
```

### Lỗi 3: Block không lặp

**Nguyên nhân**: Syntax block sai hoặc data không đúng format
**Giải pháp**:
```php
// Check data structure
print_r($data);  // Debug

// Check template có [block;block=tr] chưa
```

### Lỗi 4: Biến không hiển thị

**Nguyên nhân**: Biến không khai báo global hoặc tên sai
**Giải pháp**:
```php
global $ten_bien;  // Phải khai báo global
$ten_bien = "giá trị";

// Template: [ten_bien] (không có dấu cách, không viết hoa sai)
```

---

## 📖 Tài Liệu Tham Khảo

1. **TinyButStrong Official**: http://www.tinybutstrong.com
2. **OpenTBS Plugin**: http://www.tinybutstrong.com/plugins.php
3. **Manual**: http://www.tinybutstrong.com/manual.php
4. **Examples**: http://www.tinybutstrong.com/examples.php

---

## 💡 Tips & Tricks

### 1. Debug Template

```php
// Xem XML của subfile hiện tại
$TBS->Plugin(OPENTBS_DEBUG_XML_CURRENT, true);

// Hiển thị thông tin file trong archive
$TBS->Plugin(OPENTBS_DEBUG_INFO, true);
```

### 2. Optimize Performance

```php
// Tắt các tính năng không cần thiết
$TBS->OtbsClearWriter = false;
$TBS->OtbsClearMsWord = false;

// Giảm số lần load template
$TBS->LoadTemplate($template, OPENTBS_ALREADY_UTF8);
// Chỉ load 1 lần, merge nhiều lần
```

### 3. Dynamic Template Name

```php
$template_id = $_GET['type'];
$templates = array(
    'A' => 'template_a.docx',
    'B' => 'template_b.docx',
    'C' => 'template_c.docx'
);

if (!isset($templates[$template_id])) {
    die("Template không hợp lệ");
}

$template = $templates[$template_id];
```

### 4. Multiple Blocks

```php
// Merge nhiều block độc lập
$TBS->MergeBlock('header', $header_data);
$TBS->MergeBlock('content', $content_data);
$TBS->MergeBlock('footer', $footer_data);
```

---

## ✅ Checklist Implement

- [ ] Copy `tbs_class.php` và `tbs_plugin_opentbs.php`
- [ ] Copy các template `.docx`
- [ ] Tạo file PHP xuất Word
- [ ] Include thư viện đúng
- [ ] Khởi tạo TBS và plugin
- [ ] Load template với `OPENTBS_ALREADY_UTF8`
- [ ] Query dữ liệu từ database
- [ ] Chuẩn bị mảng dữ liệu đúng cấu trúc
- [ ] Merge block hoặc set biến global
- [ ] Clean output buffer
- [ ] Show với `OPENTBS_DOWNLOAD` hoặc `OPENTBS_FILE`
- [ ] Test với dữ liệu thực
- [ ] Validate input parameters
- [ ] Handle errors

---

## 🎓 Kết Luận

Chức năng xuất Word trong project BHLD sử dụng:
- **TinyButStrong**: Template engine mạnh mẽ, dễ dùng
- **OpenTBS**: Plugin chuyên xử lý MS Office files
- **Template-based**: Thiết kế template Word thủ công, merge dữ liệu tự động
- **Flexible**: Hỗ trợ block đơn, block lồng, biến global
- **Production-ready**: Đã được sử dụng trong thực tế

**Ưu điểm**:
✅ Dễ implement
✅ Linh hoạt, mạnh mẽ
✅ Không cần license
✅ Hỗ trợ tiếng Việt tốt
✅ Template trực quan (WYSIWYG)

**Nhược điểm**:
❌ Cần hiểu cú pháp TBS
❌ Debug template khó hơn code thuần
❌ Performance kém hơn với file lớn (>1000 rows)

---

**Tác giả**: GitHub Copilot  
**Ngày tạo**: 03/02/2026  
**Project**: BHLD - Bảo Hộ Lao Động Management System
