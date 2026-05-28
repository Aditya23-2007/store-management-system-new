package com.store.dao;

import com.store.model.Person;
import com.store.util.DBConnection;
import java.sql.*;import java.util.*;

public class PersonDAO {
    private final String table;
    public PersonDAO(String table){ if(!table.equals("customers")&&!table.equals("suppliers")) throw new IllegalArgumentException("Invalid table"); this.table=table; }
    public List<Person> getAll(){ List<Person> list=new ArrayList<>(); String sql="SELECT * FROM "+table+" ORDER BY id DESC"; try(Connection con=DBConnection.getConnection(); Statement st=con.createStatement(); ResultSet rs=st.executeQuery(sql)){ while(rs.next()){ Person p=new Person(); p.setId(rs.getInt("id")); p.setName(rs.getString("name")); p.setPhone(rs.getString("phone")); p.setEmail(rs.getString("email")); p.setAddress(rs.getString("address")); list.add(p);} }catch(SQLException e){e.printStackTrace();} return list; }
    public void save(Person p){ String sql="INSERT INTO "+table+"(name,phone,email,address) VALUES(?,?,?,?)"; try(Connection con=DBConnection.getConnection(); PreparedStatement ps=con.prepareStatement(sql)){ ps.setString(1,p.getName()); ps.setString(2,p.getPhone()); ps.setString(3,p.getEmail()); ps.setString(4,p.getAddress()); ps.executeUpdate(); }catch(SQLException e){e.printStackTrace();} }
    public void delete(int id){ String sql="DELETE FROM "+table+" WHERE id=?"; try(Connection con=DBConnection.getConnection(); PreparedStatement ps=con.prepareStatement(sql)){ ps.setInt(1,id); ps.executeUpdate(); }catch(SQLException e){e.printStackTrace();} }
}
