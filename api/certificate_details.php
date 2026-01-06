<?php
require_once 'config.php';

$method = $_SERVER['REQUEST_METHOD'];

try {
    if ($method === 'GET') {
        if (!isset($_GET['mact'])) {
            sendError('Thiếu mã chứng từ (mact)');
        }
        
        $mact = mysqli_real_escape_string($conn, $_GET['mact']);
        
        $sql = "SELECT 
                    ct.mact,
                    ct.mavt,
                    ct.dmtg,
                    ct.sl,
                    ct.ngnhan,
                    ct.ngnhantt,
                    vt.tenvt,
                    vt.dvt
                FROM bhld_ctctu ct
                LEFT JOIN bhld_dmvattu vt ON ct.mavt = vt.mavt
                WHERE ct.mact = '$mact'
                ORDER BY ct.mavt ASC";
        
        $result = mysqli_query($conn, $sql);
        $details = [];
        
        if ($result) {
            while ($row = mysqli_fetch_assoc($result)) {
                $details[] = $row;
            }
        }
        
        sendSuccess($details, 'Lấy chi tiết chứng từ thành công');
    } else {
        sendError('Method không được hỗ trợ', 405);
    }
} catch (Exception $e) {
    sendError('Lỗi server: ' . $e->getMessage(), 500);
}

mysqli_close($conn);
?>
