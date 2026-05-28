package com.store.dao;

import com.store.util.DBConnection;
import java.sql.*;

public class UserDAO {
    public boolean validate(String username, String password) {
        String sql = "SELECT id FROM users WHERE username=? AND password=?";
        try (Connection con = DBConnection.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, username);
            ps.setString(2, password);
            try (ResultSet rs = ps.executeQuery()) { return rs.next(); }
        } catch (SQLException e) { e.printStackTrace(); return false; }
    }
}
