package com.store.dao;

import com.store.model.Product;
import com.store.util.DBConnection;
import java.sql.*;import java.util.*;

public class ProductDAO {
    public List<Product> getAll() {
        List<Product> list = new ArrayList<>();
        try (Connection con = DBConnection.getConnection(); Statement st = con.createStatement(); ResultSet rs = st.executeQuery("SELECT * FROM products ORDER BY id DESC")) {
            while (rs.next()) {
                Product p = new Product(); p.setId(rs.getInt("id")); p.setName(rs.getString("name")); p.setCategory(rs.getString("category")); p.setPrice(rs.getDouble("price")); p.setQuantity(rs.getInt("quantity")); list.add(p);
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return list;
    }
    public Product getById(int id) {
        try (Connection con = DBConnection.getConnection(); PreparedStatement ps = con.prepareStatement("SELECT * FROM products WHERE id=?")) {
            ps.setInt(1,id); ResultSet rs=ps.executeQuery(); if(rs.next()){ Product p=new Product(); p.setId(rs.getInt("id")); p.setName(rs.getString("name")); p.setCategory(rs.getString("category")); p.setPrice(rs.getDouble("price")); p.setQuantity(rs.getInt("quantity")); return p; }
        } catch(SQLException e){e.printStackTrace();} return null;
    }
    public void save(Product p) {
        String sql="INSERT INTO products(name,category,price,quantity) VALUES(?,?,?,?)";
        try(Connection con=DBConnection.getConnection(); PreparedStatement ps=con.prepareStatement(sql)){ ps.setString(1,p.getName()); ps.setString(2,p.getCategory()); ps.setDouble(3,p.getPrice()); ps.setInt(4,p.getQuantity()); ps.executeUpdate(); } catch(SQLException e){e.printStackTrace();}
    }
    public void update(Product p) {
        String sql="UPDATE products SET name=?,category=?,price=?,quantity=? WHERE id=?";
        try(Connection con=DBConnection.getConnection(); PreparedStatement ps=con.prepareStatement(sql)){ ps.setString(1,p.getName()); ps.setString(2,p.getCategory()); ps.setDouble(3,p.getPrice()); ps.setInt(4,p.getQuantity()); ps.setInt(5,p.getId()); ps.executeUpdate(); } catch(SQLException e){e.printStackTrace();}
    }
    public void delete(int id) { try(Connection con=DBConnection.getConnection(); PreparedStatement ps=con.prepareStatement("DELETE FROM products WHERE id=?")){ ps.setInt(1,id); ps.executeUpdate(); } catch(SQLException e){e.printStackTrace();} }
}
