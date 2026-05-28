package com.store.util;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DBConnection {
    private static final String URL = "jdbc:mysql://localhost:3306/store_db?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true";
    private static final String USER = "root";
    private static final String PASSWORD = "aditya@123"; // change as per your MySQL password

    static {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            initializeDatabase();
        } catch (ClassNotFoundException e) {
            throw new RuntimeException("MySQL Driver not found", e);
        }
    }

    private static void initializeDatabase() {
        try (Connection con = DriverManager.getConnection(URL, USER, PASSWORD);
             java.sql.Statement st = con.createStatement()) {
            
            // Add buyer_type and unit_price to sales table
            try {
                st.execute("ALTER TABLE sales ADD COLUMN buyer_type VARCHAR(50)");
            } catch (SQLException ignore) {} // Column might already exist
            try {
                st.execute("ALTER TABLE sales ADD COLUMN unit_price DECIMAL(10,2)");
            } catch (SQLException ignore) {} // Column might already exist

            // Create departments table
            st.execute("CREATE TABLE IF NOT EXISTS departments (" +
                       "id INT AUTO_INCREMENT PRIMARY KEY," +
                       "department_name VARCHAR(150) NOT NULL UNIQUE," +
                       "contact_person VARCHAR(150)," +
                       "remarks TEXT," +
                       "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP" +
                       ")");

            // Seed departments if empty
            try (java.sql.ResultSet rs = st.executeQuery("SELECT COUNT(*) FROM departments")) {
                if (rs.next() && rs.getInt(1) == 0) {
                    st.execute("INSERT INTO departments(department_name,contact_person,remarks) VALUES " +
                               "('Computer Science','CSE Store Coordinator','Department receiving and requirement records')," +
                               "('Mechanical','Mechanical Store Coordinator','Workshop and laboratory requirements')," +
                               "('Electrical','Electrical Store Coordinator','Electrical laboratory requirements')," +
                               "('Civil','Civil Store Coordinator','Civil laboratory and office requirements')," +
                               "('Office Administration','Office Superintendent','Office and stationery requirements')");
                }
            }

            // Create item_transfers table
            st.execute("CREATE TABLE IF NOT EXISTS item_transfers (" +
                       "id INT AUTO_INCREMENT PRIMARY KEY," +
                       "product_id INT," +
                       "department_id INT," +
                       "requirement_id INT NULL," +
                       "transfer_quantity INT NOT NULL," +
                       "transfer_type VARCHAR(50) DEFAULT 'Issue'," +
                       "issued_to VARCHAR(150)," +
                       "issued_by VARCHAR(150)," +
                       "transfer_date DATE," +
                       "remarks TEXT," +
                       "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP," +
                       "FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE SET NULL," +
                       "FOREIGN KEY(department_id) REFERENCES departments(id) ON DELETE SET NULL," +
                       "FOREIGN KEY(requirement_id) REFERENCES requirements(id) ON DELETE SET NULL" +
                       ")");

            // Create scrap_items table
            st.execute("CREATE TABLE IF NOT EXISTS scrap_items (" +
                       "id INT AUTO_INCREMENT PRIMARY KEY," +
                       "product_id INT," +
                       "scrap_quantity INT NOT NULL," +
                       "scrap_reason VARCHAR(255)," +
                       "item_condition VARCHAR(150)," +
                       "approved_by VARCHAR(150)," +
                       "scrapped_by VARCHAR(150)," +
                       "scrap_date DATE," +
                       "remarks TEXT," +
                       "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP," +
                       "FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE SET NULL" +
                       ")");

        } catch (SQLException e) {
            System.err.println("Database initialization failed: " + e.getMessage());
        }
    }

    public static Connection getConnection() throws SQLException {
        return DriverManager.getConnection(URL, USER, PASSWORD);
    }
}
