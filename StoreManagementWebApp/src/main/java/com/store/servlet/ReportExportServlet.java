package com.store.servlet;

import com.lowagie.text.Document;
import com.lowagie.text.Element;
import com.lowagie.text.Font;
import com.lowagie.text.FontFactory;
import com.lowagie.text.PageSize;
import com.lowagie.text.Paragraph;
import com.lowagie.text.Phrase;
import com.lowagie.text.pdf.PdfPCell;
import com.lowagie.text.pdf.PdfPTable;
import com.lowagie.text.pdf.PdfWriter;
import com.store.util.DBConnection;
import java.io.IOException;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.Statement;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.ServletOutputStream;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.CellStyle;
import org.apache.poi.ss.usermodel.FontFormatting;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;

@WebServlet("/reportExport")
public class ReportExportServlet extends HttpServlet {

    private static final String COLLEGE_NAME = "Dr. Bapuji Salunkhe Institute of Engineering and Technology";

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String category = safe(request.getParameter("category"));
        String subcategory = safe(request.getParameter("subcategory"));
        String format = safe(request.getParameter("format"));

        if (category.isEmpty()) {
            category = "products";
        }
        if (subcategory.isEmpty()) {
            subcategory = "all";
        }
        if (format.isEmpty()) {
            format = "pdf";
        }

        ReportDefinition report = buildReport(category, subcategory);

        try (Connection con = DBConnection.getConnection();
             Statement st = con.createStatement();
             ResultSet rs = st.executeQuery(report.sql)) {

            if ("excel".equalsIgnoreCase(format) || "xlsx".equalsIgnoreCase(format)) {
                exportExcel(response, rs, report);
            } else {
                exportPdf(response, rs, report);
            }

        } catch (Exception e) {
            response.setContentType("text/plain;charset=UTF-8");
            response.getWriter().println("Report generation failed: " + e.getMessage());
        }
    }

    private ReportDefinition buildReport(String category, String subcategory) {
        String cat = category.toLowerCase();
        String sub = subcategory.toLowerCase();
        String title;
        String sql;

        switch (cat) {
            case "products":
                title = "Products Report";
                sql = "SELECT id AS 'ID', name AS 'Product Name', category AS 'Category', supplier AS 'Supplier', " +
                      "price AS 'Price', quantity AS 'Stock Quantity', status AS 'Status' FROM products";
                if ("in_stock".equals(sub)) {
                    sql += " WHERE quantity > 5";
                    title += " - In Stock";
                } else if ("low_stock".equals(sub)) {
                    sql += " WHERE quantity > 0 AND quantity <= 5";
                    title += " - Low Stock";
                } else if ("out_of_stock".equals(sub)) {
                    sql += " WHERE quantity = 0 OR LOWER(status) = 'out of stock'";
                    title += " - Out of Stock";
                } else if (isProductCategory(sub)) {
                    sql += " WHERE LOWER(category) = '" + escapeSql(subcategory) + "'";
                    title += " - " + pretty(subcategory);
                }
                sql += " ORDER BY category, name";
                break;

            case "requirements":
                title = "Department Requirements Report";
                sql = "SELECT id AS 'ID', department_name AS 'Department', requested_by AS 'Requested By', " +
                      "item_name AS 'Item Name', quantity AS 'Quantity', purpose AS 'Purpose', request_date AS 'Request Date', " +
                      "status AS 'Status' FROM requirements";
                if ("pending".equals(sub) || "approved".equals(sub) || "rejected".equals(sub)) {
                    sql += " WHERE LOWER(status) = '" + escapeSql(sub) + "'";
                    title += " - " + pretty(sub);
                }
                sql += " ORDER BY request_date DESC, id DESC";
                break;

            case "approvals":
                title = "Approvals Report";
                sql = "SELECT a.id AS 'ID', r.department_name AS 'Department', r.item_name AS 'Item Name', " +
                      "r.quantity AS 'Quantity', a.approved_by AS 'Approved By', a.approval_status AS 'Approval Status', " +
                      "a.remarks AS 'Remarks', a.approval_date AS 'Approval Date' FROM approvals a " +
                      "LEFT JOIN requirements r ON a.requirement_id = r.id";
                if ("approved".equals(sub) || "rejected".equals(sub) || "pending".equals(sub)) {
                    sql += " WHERE LOWER(a.approval_status) = '" + escapeSql(sub) + "'";
                    title += " - " + pretty(sub);
                }
                sql += " ORDER BY a.approval_date DESC, a.id DESC";
                break;

            case "purchase_orders":
                title = "Purchase Orders Report";
                sql = "SELECT po_number AS 'PO Number', supplier_name AS 'Supplier', po_date AS 'PO Date', " +
                      "total_amount AS 'Total Amount', po_status AS 'Status' FROM purchase_orders";
                if ("generated".equals(sub) || "completed".equals(sub) || "pending".equals(sub)) {
                    sql += " WHERE LOWER(po_status) = '" + escapeSql(sub) + "'";
                    title += " - " + pretty(sub);
                }
                sql += " ORDER BY po_date DESC, id DESC";
                break;

            case "received_items":
                title = "Received Items Report";
                sql = "SELECT ri.id AS 'ID', po.po_number AS 'PO Number', p.name AS 'Product', " +
                      "ri.received_quantity AS 'Received Quantity', ri.received_by AS 'Received By', " +
                      "ri.receive_date AS 'Receive Date', ri.remarks AS 'Remarks' FROM received_items ri " +
                      "LEFT JOIN purchase_orders po ON ri.po_id = po.id " +
                      "LEFT JOIN products p ON ri.product_id = p.id ORDER BY ri.receive_date DESC, ri.id DESC";
                break;

            case "item_transfers":
                title = "Department Item Transfer Report";
                sql = "SELECT it.id AS 'ID', p.name AS 'Product', d.department_name AS 'Department', " +
                      "r.item_name AS 'Requirement Item', it.transfer_quantity AS 'Transfer Quantity', " +
                      "it.transfer_type AS 'Transfer Type', it.issued_to AS 'Issued To', it.issued_by AS 'Issued By', " +
                      "it.transfer_date AS 'Transfer Date', it.remarks AS 'Remarks' FROM item_transfers it " +
                      "LEFT JOIN products p ON it.product_id = p.id " +
                      "LEFT JOIN departments d ON it.department_id = d.id " +
                      "LEFT JOIN requirements r ON it.requirement_id = r.id";
                if ("issue".equals(sub) || "replacement".equals(sub) || "temporary_transfer".equals(sub) || "return_adjustment".equals(sub)) {
                    String transferType = sub.replace('_', ' ');
                    sql += " WHERE LOWER(it.transfer_type) = '" + escapeSql(transferType) + "'";
                    title += " - " + pretty(transferType);
                }
                sql += " ORDER BY it.transfer_date DESC, it.id DESC";
                break;

            case "scrap_items":
                title = "Scrap Items Report";
                sql = "SELECT si.id AS 'ID', p.name AS 'Product', si.scrap_quantity AS 'Scrap Quantity', " +
                      "si.item_condition AS 'Condition', si.scrap_reason AS 'Reason', si.approved_by AS 'Approved By', " +
                      "si.scrapped_by AS 'Scrapped By', si.scrap_date AS 'Scrap Date', si.remarks AS 'Remarks' FROM scrap_items si " +
                      "LEFT JOIN products p ON si.product_id = p.id";
                if ("damaged".equals(sub) || "non_working".equals(sub) || "broken".equals(sub) || "expired".equals(sub) || "unusable".equals(sub) || "obsolete".equals(sub)) {
                    String condition = sub.replace('_', '-');
                    sql += " WHERE LOWER(si.item_condition) = '" + escapeSql(condition) + "'";
                    title += " - " + pretty(condition);
                }
                sql += " ORDER BY si.scrap_date DESC, si.id DESC";
                break;

            case "invoices":
                title = "Invoices and Bills Report";
                sql = "SELECT po_number AS 'PO Number', invoice_number AS 'Invoice Number', supplier_name AS 'Supplier', " +
                      "file_name AS 'File Name', invoice_amount AS 'Invoice Amount', payment_status AS 'Payment Status', " +
                      "upload_date AS 'Upload Date' FROM invoice_documents";
                if ("paid".equals(sub) || "pending".equals(sub) || "partial_payment".equals(sub)) {
                    String status = "partial_payment".equals(sub) ? "partial payment" : sub;
                    sql += " WHERE LOWER(payment_status) = '" + escapeSql(status) + "'";
                    title += " - " + pretty(status);
                }
                sql += " ORDER BY upload_date DESC, id DESC";
                break;

            case "payments":
                title = "Payments Report";
                sql = "SELECT p.id AS 'ID', i.invoice_number AS 'Invoice Number', p.supplier_name AS 'Supplier', " +
                      "p.paid_amount AS 'Paid Amount', p.payment_status AS 'Payment Status', p.payment_date AS 'Payment Date', " +
                      "p.transaction_reference AS 'Transaction Reference', p.remarks AS 'Remarks' FROM payments p " +
                      "LEFT JOIN invoice_documents i ON p.invoice_document_id = i.id";
                if ("paid".equals(sub) || "pending".equals(sub) || "partial_payment".equals(sub)) {
                    String status = "partial_payment".equals(sub) ? "partial payment" : sub;
                    sql += " WHERE LOWER(p.payment_status) = '" + escapeSql(status) + "'";
                    title += " - " + pretty(status);
                }
                sql += " ORDER BY p.payment_date DESC, p.id DESC";
                break;

            case "suppliers":
                title = "Suppliers Report";
                sql = "SELECT id AS 'ID', name AS 'Supplier Name', email AS 'Email', phone AS 'Phone', " +
                      "address AS 'Address' FROM suppliers ORDER BY name";
                break;

            case "users":
                title = "Users Report";
                sql = "SELECT id AS 'ID', username AS 'Username', full_name AS 'Full Name', email AS 'Email', role AS 'Role' FROM users";
                if ("admin".equals(sub) || "store".equals(sub) || "director".equals(sub) || "user".equals(sub)) {
                    sql += " WHERE LOWER(role) = '" + escapeSql(sub) + "'";
                    title += " - " + pretty(sub);
                }
                sql += " ORDER BY role, username";
                break;

            default:
                title = "Products Report";
                sql = "SELECT id AS 'ID', name AS 'Product Name', category AS 'Category', supplier AS 'Supplier', " +
                      "price AS 'Price', quantity AS 'Stock Quantity', status AS 'Status' FROM products ORDER BY category, name";
                break;
        }

        return new ReportDefinition(title, category, subcategory, sql);
    }

    private void exportExcel(HttpServletResponse response, ResultSet rs, ReportDefinition report) throws Exception {
        response.setContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
        response.setHeader("Content-Disposition", "attachment; filename=\"" + fileName(report, "xlsx") + "\"");

        try (Workbook workbook = new XSSFWorkbook(); ServletOutputStream out = response.getOutputStream()) {
            Sheet sheet = workbook.createSheet("Report");

            org.apache.poi.ss.usermodel.Font titleFont = workbook.createFont();
            titleFont.setBold(true);
            titleFont.setFontHeightInPoints((short) 14);
            CellStyle titleStyle = workbook.createCellStyle();
            titleStyle.setFont(titleFont);

            org.apache.poi.ss.usermodel.Font headerFont = workbook.createFont();
            headerFont.setBold(true);
            CellStyle headerStyle = workbook.createCellStyle();
            headerStyle.setFont(headerFont);

            int rowIndex = 0;
            Row row = sheet.createRow(rowIndex++);
            Cell cell = row.createCell(0);
            cell.setCellValue(COLLEGE_NAME);
            cell.setCellStyle(titleStyle);

            row = sheet.createRow(rowIndex++);
            row.createCell(0).setCellValue(report.title);

            row = sheet.createRow(rowIndex++);
            row.createCell(0).setCellValue("Generated On: " + new SimpleDateFormat("dd-MM-yyyy HH:mm").format(new Date()));
            rowIndex++;

            ResultSetMetaData meta = rs.getMetaData();
            int cols = meta.getColumnCount();

            Row header = sheet.createRow(rowIndex++);
            for (int i = 1; i <= cols; i++) {
                Cell h = header.createCell(i - 1);
                h.setCellValue(meta.getColumnLabel(i));
                h.setCellStyle(headerStyle);
            }

            while (rs.next()) {
                Row dataRow = sheet.createRow(rowIndex++);
                for (int i = 1; i <= cols; i++) {
                    Object val = rs.getObject(i);
                    dataRow.createCell(i - 1).setCellValue(val == null ? "" : String.valueOf(val));
                }
            }

            for (int i = 0; i < cols; i++) {
                sheet.autoSizeColumn(i);
            }

            workbook.write(out);
        }
    }

    private void exportPdf(HttpServletResponse response, ResultSet rs, ReportDefinition report) throws Exception {
        response.setContentType("application/pdf");
        response.setHeader("Content-Disposition", "attachment; filename=\"" + fileName(report, "pdf") + "\"");

        Document document = new Document(PageSize.A4.rotate(), 24, 24, 30, 24);
        PdfWriter.getInstance(document, response.getOutputStream());
        document.open();

        Font collegeFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 16);
        Font titleFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 13);
        Font smallFont = FontFactory.getFont(FontFactory.HELVETICA, 9);
        Font headerFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 9);
        Font bodyFont = FontFactory.getFont(FontFactory.HELVETICA, 8);

        Paragraph college = new Paragraph(COLLEGE_NAME, collegeFont);
        college.setAlignment(Element.ALIGN_CENTER);
        document.add(college);

        Paragraph title = new Paragraph(report.title, titleFont);
        title.setAlignment(Element.ALIGN_CENTER);
        title.setSpacingAfter(6);
        document.add(title);

        Paragraph generated = new Paragraph("Generated On: " + new SimpleDateFormat("dd-MM-yyyy HH:mm").format(new Date()), smallFont);
        generated.setAlignment(Element.ALIGN_CENTER);
        generated.setSpacingAfter(12);
        document.add(generated);

        ResultSetMetaData meta = rs.getMetaData();
        int cols = meta.getColumnCount();
        PdfPTable table = new PdfPTable(cols);
        table.setWidthPercentage(100);

        for (int i = 1; i <= cols; i++) {
            PdfPCell cell = new PdfPCell(new Phrase(meta.getColumnLabel(i), headerFont));
            cell.setHorizontalAlignment(Element.ALIGN_CENTER);
            cell.setBackgroundColor(new java.awt.Color(230, 236, 245));
            cell.setPadding(5);
            table.addCell(cell);
        }

        while (rs.next()) {
            for (int i = 1; i <= cols; i++) {
                Object val = rs.getObject(i);
                PdfPCell cell = new PdfPCell(new Phrase(val == null ? "" : String.valueOf(val), bodyFont));
                cell.setPadding(4);
                table.addCell(cell);
            }
        }

        document.add(table);
        document.close();
    }

    private String fileName(ReportDefinition report, String ext) {
        String base = report.category + "_" + report.subcategory + "_report";
        base = base.replaceAll("[^A-Za-z0-9_]+", "_");
        return base + "_" + new SimpleDateFormat("yyyyMMdd_HHmmss").format(new Date()) + "." + ext;
    }

    private boolean isProductCategory(String sub) {
        return "tech".equals(sub) || "fashion".equals(sub) || "electronic".equals(sub) || "stationery".equals(sub);
    }

    private String safe(String v) {
        return v == null ? "" : v.trim();
    }

    private String escapeSql(String v) {
        return v == null ? "" : v.toLowerCase().replace("'", "''");
    }

    private String pretty(String v) {
        if (v == null) {
            return "All";
        }
        String[] parts = v.replace('_', ' ').split(" ");
        StringBuilder out = new StringBuilder();
        for (String p : parts) {
            if (p.length() > 0) {
                out.append(Character.toUpperCase(p.charAt(0))).append(p.substring(1).toLowerCase()).append(' ');
            }
        }
        return out.toString().trim();
    }

    private static class ReportDefinition {
        String title;
        String category;
        String subcategory;
        String sql;

        ReportDefinition(String title, String category, String subcategory, String sql) {
            this.title = title;
            this.category = category;
            this.subcategory = subcategory;
            this.sql = sql;
        }
    }
}
