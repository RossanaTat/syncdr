# print.syncdr_status prints full synchronization summary

    Code
      print(s)
    Message
      
      -- Synchronization Summary -----------------------------------------------------
      * Left Directory: 'C:/Users/wb621604/AppData/Local/Temp/RtmpK0WFY2/left'
      * Right Directory: 'C:/Users/wb621604/AppData/Local/Temp/RtmpK0WFY2/right'
      * Total Common Files: 6
      * Total Non-common Files: 9
      * Compare files by: date & content
      
      -- Common files ----------------------------------------------------------------
    Output
                  path modification_time_left modification_time_right modified
      1 /left/B/B1.Rds    2025-12-02 11:58:23     2025-12-02 11:58:24    right
      2 /left/B/B2.Rds    2025-12-02 11:58:26     2025-12-02 11:58:27    right
      3 /left/C/C2.Rds    2025-12-02 11:58:27     2025-12-02 11:58:28    right
      4 /left/C/C3.Rds    2025-12-02 11:58:29     2025-12-02 11:58:30    right
      5 /left/D/D1.Rds    2025-12-02 11:58:26     2025-12-02 11:58:25     left
      6 /left/D/D2.Rds    2025-12-02 11:58:29     2025-12-02 11:58:28     left
              sync_status
      1 different content
      2 different content
      3 different content
      4 different content
      5 different content
      6 different content
    Message
      
      -- Non-common files ------------------------------------------------------------
      
      -- Only in left --
      
    Output
      # A tibble: 4 x 1
        path_left     
        <fs::path>    
      1 /left/A/A1.Rds
      2 /left/A/A2.Rds
      3 /left/A/A3.Rds
      4 /left/B/B3.Rds
      
    Message
      -- Only in right --
      
    Output
      # A tibble: 5 x 1
        path_right               
        <fs::path>               
      1 /right/C/C1_duplicate.Rds
      2 /right/D/D3.Rds          
      3 /right/E/E1.Rds          
      4 /right/E/E2.Rds          
      5 /right/E/E3.Rds          

---

    Code
      print(s)
    Message
      
      -- Synchronization Summary -----------------------------------------------------
      * Left Directory: 'C:/Users/wb621604/AppData/Local/Temp/RtmpU3H7Xn/left'
      * Right Directory: 'C:/Users/wb621604/AppData/Local/Temp/RtmpU3H7Xn/right'
      * Total Common Files: 7
      * Total Non-common Files: 9
      * Compare files by: content
      
      -- Common files ----------------------------------------------------------------
    Output
                  path       sync_status
      1 /left/B/B1.Rds different content
      2 /left/B/B2.Rds different content
      3 /left/C/C1.Rds      same content
      4 /left/C/C2.Rds different content
      5 /left/C/C3.Rds different content
      6 /left/D/D1.Rds different content
      7 /left/D/D2.Rds different content
    Message
      
      -- Non-common files ------------------------------------------------------------
      
      -- Only in left --
      
    Output
      # A tibble: 4 x 1
        path_left     
        <fs::path>    
      1 /left/A/A1.Rds
      2 /left/A/A2.Rds
      3 /left/A/A3.Rds
      4 /left/B/B3.Rds
      
    Message
      -- Only in right --
      
    Output
      # A tibble: 5 x 1
        path_right               
        <fs::path>               
      1 /right/C/C1_duplicate.Rds
      2 /right/D/D3.Rds          
      3 /right/E/E1.Rds          
      4 /right/E/E2.Rds          
      5 /right/E/E3.Rds          

---

    Code
      print(s)
    Message
      
      -- Synchronization Summary -----------------------------------------------------
      * Left Directory: 'C:/Users/wb621604/AppData/Local/Temp/RtmpU3H7Xn/left'
      * Right Directory: 'C:/Users/wb621604/AppData/Local/Temp/RtmpU3H7Xn/right'
      * Total Common Files: 7
      * Total Non-common Files: 9
      * Compare files by: date
      
      -- Common files ----------------------------------------------------------------
    Output
                  path modification_time_left modification_time_right  modified
      1 /left/B/B1.Rds    2025-12-02 12:03:16     2025-12-02 12:03:17     right
      2 /left/B/B2.Rds    2025-12-02 12:03:19     2025-12-02 12:03:20     right
      3 /left/C/C1.Rds    2025-12-02 12:03:17     2025-12-02 12:03:17 same date
      4 /left/C/C2.Rds    2025-12-02 12:03:20     2025-12-02 12:03:21     right
      5 /left/C/C3.Rds    2025-12-02 12:03:22     2025-12-02 12:03:23     right
      6 /left/D/D1.Rds    2025-12-02 12:03:19     2025-12-02 12:03:18      left
      7 /left/D/D2.Rds    2025-12-02 12:03:22     2025-12-02 12:03:21      left
    Message
      
      -- Non-common files ------------------------------------------------------------
      
      -- Only in left --
      
    Output
      # A tibble: 4 x 1
        path_left     
        <fs::path>    
      1 /left/A/A1.Rds
      2 /left/A/A2.Rds
      3 /left/A/A3.Rds
      4 /left/B/B3.Rds
      
    Message
      -- Only in right --
      
    Output
      # A tibble: 5 x 1
        path_right               
        <fs::path>               
      1 /right/C/C1_duplicate.Rds
      2 /right/D/D3.Rds          
      3 /right/E/E1.Rds          
      4 /right/E/E2.Rds          
      5 /right/E/E3.Rds          

