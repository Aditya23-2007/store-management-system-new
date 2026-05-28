package com.store.servlet;

import com.store.util.DBConnection;
import java.io.*;
import java.nio.file.*;
import java.sql.*;
import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

@WebServlet("/invoiceUpload")
@MultipartConfig(maxFileSize = 10 * 1024 * 1024, maxRequestSize = 12 * 1024 * 1024)
public class InvoiceUploadServlet extends HttpServlet {
    @Override protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        String poNumber = request.getParameter("po_number");
        String invoiceNumber = request.getParameter("invoice_number");
        String supplierName = request.getParameter("supplier_name");
        String amountText = request.getParameter("amount");
        double amount = 0; try { amount = Double.parseDouble(amountText); } catch(Exception ignored) {}
        String paymentStatus = request.getParameter("payment_status"); if(paymentStatus == null || paymentStatus.isBlank()) paymentStatus = "Pending";

        Part part = request.getPart("invoice_file");
        String submitted = part == null ? "" : Paths.get(part.getSubmittedFileName()).getFileName().toString();
        String safeName = submitted.replaceAll("[^a-zA-Z0-9._-]", "_");
        if (safeName.isBlank()) safeName = "no_file.txt";
        String prefix = invoiceNumber == null || invoiceNumber.isBlank() ? String.valueOf(System.currentTimeMillis()) : invoiceNumber.replaceAll("[^a-zA-Z0-9._-]", "_");
        String finalName = prefix + "_" + safeName;

        String uploadDirPath = getServletContext().getRealPath("/uploads/invoices");
        File uploadDir = new File(uploadDirPath);
        if (!uploadDir.exists()) uploadDir.mkdirs();
        File outFile = new File(uploadDir, finalName);
        if (part != null && part.getSize() > 0) {
            try (InputStream in = part.getInputStream()) { Files.copy(in, outFile.toPath(), StandardCopyOption.REPLACE_EXISTING); }
        }
        String filePath = "uploads/invoices/" + finalName;
        String json = "{"
                + "\"po_number\":" + q(poNumber) + ","
                + "\"invoice_number\":" + q(invoiceNumber) + ","
                + "\"supplier_name\":" + q(supplierName) + ","
                + "\"file_name\":" + q(finalName) + ","
                + "\"file_path\":" + q(filePath) + ","
                + "\"invoice_amount\":" + amount + ","
                + "\"payment_status\":" + q(paymentStatus)
                + "}";
        try (Connection con = DBConnection.getConnection(); PreparedStatement ps = con.prepareStatement("INSERT INTO invoice_documents(po_number,invoice_number,supplier_name,file_name,file_path,json_metadata,invoice_amount,payment_status) VALUES (?,?,?,?,?,?,?,?)")) {
            ps.setString(1, poNumber); ps.setString(2, invoiceNumber); ps.setString(3, supplierName); ps.setString(4, finalName); ps.setString(5, filePath); ps.setString(6, json); ps.setDouble(7, amount); ps.setString(8, paymentStatus); ps.executeUpdate();
        } catch(SQLException e) { throw new ServletException(e); }
        response.sendRedirect("invoices.jsp?uploaded=1");
    }
    private String q(String s) { if (s == null) s = ""; return "\"" + s.replace("\\", "\\\\").replace("\"", "\\\"") + "\""; }
}
