<?php
require_once 'config.php';

$method = $_SERVER['REQUEST_METHOD'];

try {
    if ($method === 'GET') {
        // Get single employee by manv
        if (isset($_GET['manv'])) {
            $manv = mysqli_real_escape_string($conn, $_GET['manv']);
            
            $sql = "SELECT 
                        nv.manv,
                        nv.tennhanvien,
                        nv.mapb,
                        nv.dinhmuc,
                        pb.tenphong as tenphongban
                    FROM bhld_nhanvien nv
                    LEFT JOIN bhld_phongban pb ON nv.mapb = pb.mapb
                    WHERE nv.manv = '$manv'
                    LIMIT 1";
            
            $result = mysqli_query($conn, $sql);
            
            if ($result && mysqli_num_rows($result) > 0) {
                $employee = mysqli_fetch_assoc($result);
                sendSuccess($employee, 'Lấy thông tin nhân viên thành công');
            } else {
                sendError('Không tìm thấy nhân viên', 404);
            }
        }
        // Get list of employees with optional search
        else {
            $search = isset($_GET['search']) ? mysqli_real_escape_string($conn, $_GET['search']) : '';
            
            $sql = "SELECT 
                        nv.manv,
                        nv.tennhanvien,
                        nv.mapb,
                        nv.dinhmuc,
                        pb.tenphong as tenphongban
                    FROM bhld_nhanvien nv
                    LEFT JOIN bhld_phongban pb ON nv.mapb = pb.mapb
                    WHERE 1=1";
            
            if (!empty($search)) {
                $sql .= " AND (nv.manv LIKE '%$search%' 
                          OR nv.tennhanvien LIKE '%$search%')";
            }
            
            $sql .= " ORDER BY nv.manv ASC";
            
            $result = mysqli_query($conn, $sql);
            $employees = [];
            
            if ($result) {
                while ($row = mysqli_fetch_assoc($result)) {
                    $employees[] = $row;
                }
            }
            
            sendSuccess($employees, 'Lấy danh sách nhân viên thành công');
        }
    } 
    elseif ($method === 'PUT') {
        // Update employee name
        $input = json_decode(file_get_contents('php://input'), true);
        
        if (!isset($input['manv']) || !isset($input['tennhanvien'])) {
            sendError('Thiếu thông tin manv hoặc tennhanvien', 400);
        }
        
        $manv = mysqli_real_escape_string($conn, $input['manv']);
        $tennhanvien = mysqli_real_escape_string($conn, $input['tennhanvien']);
        
        $sql = "UPDATE bhld_nhanvien 
                SET tennhanvien = '$tennhanvien' 
                WHERE manv = '$manv'";
        
        if (mysqli_query($conn, $sql)) {
            if (mysqli_affected_rows($conn) > 0) {
                sendSuccess(['manv' => $manv, 'tennhanvien' => $tennhanvien], 
                           'Cập nhật tên nhân viên thành công');
            } else {
                sendError('Không tìm thấy nhân viên hoặc tên không thay đổi', 404);
            }
        } else {
            sendError('Lỗi cập nhật: ' . mysqli_error($conn), 500);
        }
    }
    else {
        sendError('Method không được hỗ trợ', 405);
    }
} catch (Exception $e) {
    sendError('Lỗi server: ' . $e->getMessage(), 500);
}

mysqli_close($conn);
?>
