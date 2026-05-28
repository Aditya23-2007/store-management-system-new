package com.store.dao;

import com.store.util.DBConnection;
import java.sql.*;import java.util.*;

public class SalesDAO {
    public boolean createSale(int productId, String customerName, int qty) {
        String get="SELECT price,quantity FROM products WHERE id=?";
        String sale="INSERT INTO sales(product_id,customer_name,quantity,total_amount) VALUES(?,?,?,?)";
        String upd="UPDATE products SET quantity=quantity-? WHERE id=?";
        try(Connection con=DBConnection.getConnection()){
            con.setAutoCommit(false);
            try(PreparedStatement ps=con.prepareStatement(get)){ ps.setInt(1,productId); ResultSet rs=ps.executeQuery(); if(!rs.next()||rs.getInt("quantity")<qty){ con.rollback(); return false; } double total=rs.getDouble("price")*qty;
                try(PreparedStatement ps2=con.prepareStatement(sale); PreparedStatement ps3=con.prepareStatement(upd)){ ps2.setInt(1,productId); ps2.setString(2,customerName); ps2.setInt(3,qty); ps2.setDouble(4,total); ps2.executeUpdate(); ps3.setInt(1,qty); ps3.setInt(2,productId); ps3.executeUpdate(); con.commit(); return true; }
            }
        }catch(SQLException e){e.printStackTrace(); return false;}
    }
    public List<Map<String,Object>> salesReport(){ List<Map<String,Object>> list=new ArrayList<>(); String sql="SELECT s.id,p.name product,s.customer_name,s.quantity,s.total_amount,s.sale_date FROM sales s JOIN products p ON s.product_id=p.id ORDER BY s.id DESC"; try(Connection con=DBConnection.getConnection(); Statement st=con.createStatement(); ResultSet rs=st.executeQuery(sql)){ while(rs.next()){ Map<String,Object> m=new HashMap<>(); m.put("id",rs.getInt("id")); m.put("product",rs.getString("product")); m.put("customer",rs.getString("customer_name")); m.put("quantity",rs.getInt("quantity")); m.put("total",rs.getDouble("total_amount")); m.put("date",rs.getTimestamp("sale_date")); list.add(m);} }catch(SQLException e){e.printStackTrace();} return list; }
    public Map<String,Object> dashboard(){ Map<String,Object> m=new HashMap<>(); try(Connection con=DBConnection.getConnection(); Statement st=con.createStatement()){ m.put("products", count(st,"products")); m.put("customers", count(st,"customers")); m.put("suppliers", count(st,"suppliers")); ResultSet rs=st.executeQuery("SELECT COALESCE(SUM(total_amount),0) total FROM sales"); rs.next(); m.put("sales", rs.getDouble("total")); }catch(SQLException e){e.printStackTrace();} return m; }
    private int count(Statement st,String table)throws SQLException{ ResultSet rs=st.executeQuery("SELECT COUNT(*) c FROM "+table); rs.next(); return rs.getInt("c"); }
}
