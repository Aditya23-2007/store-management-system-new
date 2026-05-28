package com.store.servlet;

import com.store.util.DBConnection;
import java.io.*;
import java.sql.*;
import java.util.*;
import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

@WebServlet("/admin/update")
@MultipartConfig(maxFileSize = 20 * 1024 * 1024, maxRequestSize = 25 * 1024 * 1024)
public class UpdateServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        request.setCharacterEncoding("UTF-8");
        response.setContentType("text/html;charset=UTF-8");
        
        // Strict Security Check: Admin role required
        HttpSession session = request.getSession(false);
        if (session == null || !"admin".equals(session.getAttribute("role"))) {
            response.sendRedirect(request.getContextPath() + "/dashboard.jsp?access=denied");
            return;
        }

        String action = request.getParameter("action");
        String messageType = "success";
        String messageText = "";
        
        if ("sql".equals(action)) {
            // --- DATABASE UPDATE LOGIC ---
            String sqlQuery = request.getParameter("sql_query");
            Part sqlFilePart = request.getPart("sql_file");
            
            StringBuilder sqlBuilder = new StringBuilder();
            
            // 1. Read from pasted query
            if (sqlQuery != null && !sqlQuery.trim().isEmpty()) {
                sqlBuilder.append(sqlQuery);
            }
            
            // 2. Read from uploaded SQL file
            if (sqlFilePart != null && sqlFilePart.getSize() > 0) {
                try (BufferedReader reader = new BufferedReader(
                        new InputStreamReader(sqlFilePart.getInputStream(), "UTF-8"))) {
                    String line;
                    while ((line = reader.readLine()) != null) {
                        sqlBuilder.append(line).append("\n");
                    }
                }
            }
            
            String fullSql = sqlBuilder.toString().trim();
            if (fullSql.isEmpty()) {
                messageType = "error";
                messageText = "No SQL commands or file provided.";
            } else {
                int successCount = 0;
                int failureCount = 0;
                List<String> errors = new ArrayList<>();
                
                // Parse and execute statements divided by semicolon
                try (Connection conn = DBConnection.getConnection()) {
                    conn.setAutoCommit(false);
                    
                    // Simple SQL splitter (handles newlines and basic semicolon delimiters)
                    String[] statements = fullSql.split(";");
                    for (String stmtText : statements) {
                        stmtText = stmtText.trim();
                        if (stmtText.isEmpty() || stmtText.startsWith("--") || stmtText.startsWith("#")) {
                            continue;
                        }
                        
                        try (Statement st = conn.createStatement()) {
                            st.execute(stmtText);
                            successCount++;
                        } catch (SQLException ex) {
                            failureCount++;
                            errors.add("Error executing [" + stmtText.substring(0, Math.min(stmtText.length(), 60)) + "...]: " + ex.getMessage());
                        }
                    }
                    
                    if (failureCount == 0) {
                        conn.commit();
                        messageText = "Database updated successfully. Executed " + successCount + " statement(s).";
                    } else {
                        conn.rollback();
                        messageType = "error";
                        messageText = "Executed " + successCount + " successfully. Failed " + failureCount + " statement(s). Changes rolled back.\nErrors:\n" + String.join("\n", errors);
                    }
                    
                } catch (Exception ex) {
                    messageType = "error";
                    messageText = "Database connection error: " + ex.getMessage();
                }
            }
            
        } else if ("file".equals(action)) {
            // --- FILE UPDATE / HOTPATCH LOGIC ---
            String targetPath = request.getParameter("target_path");
            Part filePart = request.getPart("upload_file");
            
            if (targetPath == null || targetPath.trim().isEmpty()) {
                messageType = "error";
                messageText = "Target file path is required.";
            } else if (filePart == null || filePart.getSize() == 0) {
                messageType = "error";
                messageText = "No file selected for upload.";
            } else {
                targetPath = targetPath.trim().replace('\\', '/');
                if (targetPath.startsWith("/")) {
                    targetPath = targetPath.substring(1);
                }
                
                // Prevent directory traversal attacks outside the application scope unless required
                if (targetPath.contains("../")) {
                    messageType = "error";
                    messageText = "Invalid target path. Directory traversal (../) is not allowed.";
                } else {
                    String baseDir = getServletContext().getRealPath("/");
                    File targetFile = new File(baseDir, targetPath);
                    
                    try {
                        // Create parent directories if they do not exist
                        File parent = targetFile.getParentFile();
                        if (parent != null && !parent.exists()) {
                            parent.mkdirs();
                        }
                        
                        // Write the file
                        try (InputStream in = filePart.getInputStream();
                             OutputStream out = new FileOutputStream(targetFile)) {
                            byte[] buffer = new byte[8192];
                            int read;
                            while ((read = in.read(buffer)) != -1) {
                                out.write(buffer, 0, read);
                            }
                        }
                        
                        messageText = "File patched successfully at: " + targetPath + " (" + filePart.getSize() + " bytes)";
                    } catch (IOException ex) {
                        messageType = "error";
                        messageText = "Failed to write file: " + ex.getMessage();
                    }
                }
            }
        } else {
            messageType = "error";
            messageText = "Invalid update action specified.";
        }
        
        // Save execution output in session and redirect back to the form
        session.setAttribute("update_msg_type", messageType);
        session.setAttribute("update_msg_text", messageText);
        response.sendRedirect(request.getContextPath() + "/updates.jsp");
    }
}
