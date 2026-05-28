<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dr. Bapuji Salunkhe Institute of Engineering and Technology - Store Management System</title>

    <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@400;700;900&family=DM+Sans:wght@300;400;500;600&display=swap" rel="stylesheet">

    <link rel="stylesheet" href="<%=request.getContextPath()%>/css/login.css">
</head>

<body>

<div class="wrapper">

    <div class="left-panel">
        <div class="orb"></div>

        <div class="left-content">

            <div class="founder-ring">
                <img src="<%=request.getContextPath()%>/images/founder.png"
                     class="founder-img"
                     alt="Founder">
            </div>

            <div class="sanstha-name">
                Shree Swami Vivekanand Shikshan Sanstha's
            </div>

            <div class="college-name">
                Dr. Bapuji Salunkhe<br>
                <span>Institute of Engineering</span><br>
                &amp; Technology
            </div>

            <div class="college-location">
                Kolhapur, Maharashtra 416003
            </div>

            <div class="divider-line"></div>

            <p class="college-description">
                Empowering future engineers with knowledge, innovation &amp; excellence since inception.
            </p>

            <div class="extra-btns">
                <button type="button" class="btn-extra btn-credit" onclick="showModal('credit')">
                    🏅 Credits
                </button>

                <button type="button" class="btn-extra btn-help" onclick="showModal('help')">
                    ❓ Help
                </button>
            </div>

        </div>
    </div>

    <div class="right-panel">

        <!--
            Building image is NOT removed from JSP.
            It is controlled from login.css using:
            .building-bg { background: ..., url('../images/bsiet_building.png') center/cover no-repeat; }
            Keep your file at: src/main/webapp/images/bsiet_building.png
        -->
        <div class="building-bg"></div>
        <div class="accent-stripe"></div>


        <div class="login-card">

            <div class="badge">
                <span class="badge-dot"></span>
                Store Management System
            </div>

            <h1 class="card-title">Welcome to Store Portal</h1>
            <p class="card-subtitle">Sign in to your store portal</p>

            <% if(request.getAttribute("error") != null) { %>
                <div class="error-message">
                    <%= request.getAttribute("error") %>
                </div>
            <% } %>

            <form action="<%=request.getContextPath()%>/login" method="post">

                <div class="form-group">
                    <label class="form-label">Username</label>

                    <div class="input-wrap">
                        <span class="input-icon">👤</span>
                        <input class="form-input"
                               type="text"
                               name="username"
                               placeholder="Enter username"
                               required>
                    </div>
                </div>

                <div class="form-group">
                    <label class="form-label">Password</label>

                    <div class="input-wrap">
                        <span class="input-icon">🔒</span>
                        <input class="form-input"
                               type="password"
                               name="password"
                               id="pwdInput"
                               placeholder="Enter password"
                               required>

                        <button type="button"
                                class="eye-btn"
                                onclick="togglePwd()"
                                title="Show/Hide">👁</button>
                    </div>
                </div>

                <div class="form-row">
                    <label class="remember">
                        <input type="checkbox" checked>
                        Remember me
                    </label>

                    <a href="#" class="forgot">Forgot password?</a>
                </div>

                <button type="submit" class="btn-signin">
                    Sign In to Portal
                </button>

            </form>

            <div class="or-divider">or</div>

            <button type="button" class="btn-register">
                New user? Contact administrator ↗
            </button>

        </div>

        <div class="system-tag">
            Dr. Bapuji Salunkhe Institute of Engineering and Technology · Portal v2.0
        </div>

    </div>

</div>

<div id="modalOverlay" onclick="closeModal()"></div>

<div id="modalBox">
    <h2 id="modalTitle"></h2>
    <p id="modalBody"></p>

    <button type="button" onclick="closeModal()" class="modal-close-btn">
        Close
    </button>
</div>

<audio id="creditsMusic" preload="auto">
    <source src="<%=request.getContextPath()%>/audio/credits.mp3" type="audio/mpeg">
</audio>

<script>
    function togglePwd() {
        const p = document.getElementById("pwdInput");
        p.type = p.type === "password" ? "text" : "password";
    }
const content = {
        credit: {
            title: "🏅 Credits",

            body: `

            <div class="credit-header">

                <div class="credit-main-title">
                    Shree Swami Vivekanand Shikshan Sanstha's
             </div>
               <div class="credit-main-title"> 
                    Dr. Bapuji Salunkhe Institute of Engineering and Technology
                </div>

                <div class="credit-sub">
                    Department of Computer Science Engineering
                </div>

                <div class="credit-sub">
                    Store Management System
                </div>

                <div class="credit-sub">
                    Academic Year 2025-26
                </div>

                <div class="credit-leader">
                    Project Commander: Dr. Rajendra D. Bhosale
                </div>

            </div>

            <div class="credit-grid">

                <div class="credit-section">
                    <h3>Client Interaction Team</h3>
                    <p>
                        Fahim Bagwan - Vision Lead<br>
                        Omkar - Coordinator X<br>
                        Sanjyot Dasre - Client Bridge<br>
                        Vaishnavi Powar - Strategy Voice<br>
                        Paras Patil - Connect Captain<br>
                        Manasvi Akode - Insight Lead<br>
                        Damini - Relation Manager<br>
                        Shrutika - Communication Ace
                    </p>
                </div>

                <div class="credit-section">
                    <h3>Documentation Team</h3>
                    <p>
                        Manasvi Akode - DocMaster<br>
                        Fahim - Content Architect<br>
                        Omkar - Structure Lead<br>
                        Pushkar - Report Designer
                    </p>
                </div>

                <div class="credit-section">
                    <h3>User Form Team</h3>
                    <p>
                        Sharvari Tavade - UI Queen<br>
                        Pallavi Jadhav - Form Designer<br>
                        Shezan Madre - Logic Builder<br>
                        Nilam Salunkhe - Input Manager<br>
                        Gayatri Patil - UX Support
                    </p>
                </div>

                <div class="credit-section">
                    <h3>Database Team</h3>
                    <p>
                        Aditya Powar - Data Chief<br>
                        Vasundhara Bagal - Query Queen<br>
                        Rajnandini Patil - SQL Commander<br>
                        Dnyanesh Dambe - Schema Expert<br>
                        Dhanashri Bondre - Data Guardian
                    </p>
                </div>

                <div class="credit-section">
                    <h3>LAN Setup Team</h3>
                    <p>
                        Sohaib Takildar - Network Ninja<br>
                        Omkar - LAN Commander<br>
                        Rajnandini Patil - IP Manager<br>
                        Shezan Madre - Connection Lead<br>
                        Nilam Salunkhe - System Integrator<br>
                        Vasundhara Bagal - Port Manager<br>
                        Dhanashri Bondre - Deployment Expert
                    </p>
                </div>

                <div class="credit-section">
                    <h3>Report Team</h3>
                    <p>
                        Ranjeet Pawar - Report Captain<br>
                        Chetan Mohite - Presentation Pro<br>
                        Fahim - Review Lead<br>
                        Omkar - Final Compiler<br>
                        Prachi Patil - Design Specialist
                    </p>
                </div>

            </div>

            <div class="credit-footer">
                Store Management System - All rights reserved © Dr. Bapuji Salunkhe Institute of Engineering and Technology
            </div>

            `
        },

        help: {
            title: "❓ Help & Support",
            body: `<strong>How to Sign In:</strong><br>
                   Enter your username and password, then click Sign In to Portal.<br><br>
                   <strong>Default Login:</strong><br>
                   Username: admin<br>
                   Password: admin123<br><br>
                   <strong>Contact Support:</strong><br>
                   Department of Computer Science Engineering, Dr. Bapuji Salunkhe Institute of Engineering and Technology`
        }
    };

    function showModal(type) {
        document.getElementById("modalTitle").innerHTML = content[type].title;
        document.getElementById("modalBody").innerHTML = content[type].body;

        const overlay = document.getElementById("modalOverlay");
        const box = document.getElementById("modalBox");

        overlay.style.display = "flex";
        box.style.display = "block";

        requestAnimationFrame(() => {
            box.style.transform = "translate(-50%, -50%) scale(1)";
            box.style.opacity = "1";
        });

        if (type === "credit") {
            const music = document.getElementById("creditsMusic");
            if (music) {
                music.currentTime = 0;
                music.volume = 0.35;
                music.play().catch(function() {
                    /* Some browsers may block autoplay until user interaction. */
                });
            }
        }
    }

    function closeModal() {
        const box = document.getElementById("modalBox");

        box.style.transform = "translate(-50%, -50%) scale(0.9)";
        box.style.opacity = "0";

        const music = document.getElementById("creditsMusic");
        if (music) {
            music.pause();
            music.currentTime = 0;
        }

        setTimeout(() => {
            document.getElementById("modalOverlay").style.display = "none";
            box.style.display = "none";
        }, 230);
    }
</script>

</body>
</html>
