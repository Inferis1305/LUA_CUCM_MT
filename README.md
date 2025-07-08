# LUA_CUCM_MT
LUA normalization script to addopt MT Locations to CUCM dial-plan

![image](https://github.com/user-attachments/assets/d445299a-1f80-477a-804a-8f96cf182501)

This LUA enables flexible setup where MT sends calls through one trunk per region, and a location ID in the SIP header tells CUCM where the location of the user is. A LUA script adds a prefix to the called number, and CUCM routes the call to the right PSTN gateway using its regular logic .This avoids the complexity of having many SIP trunks and works well with both MT’s location-based routing and CUCM’s traditional routing model.

![image](https://github.com/user-attachments/assets/f2d71fa6-fc65-4da4-bb0c-b0b2218a3aa0)

Parameters information:
![image](https://github.com/user-attachments/assets/9afc17cc-0cdf-4f9e-9a8d-3d91c5358858)
