GROUP INFO

Jacob Ville			4540-7373<br>
Shaifil Maknojia	7805-9466<br>

***

#### Instructions:

1. Extract the zip file
2. Go to proj2 folder
3. mix escript.build
4. ./proj2 num_actors topology algorithm<br>

    num_actors  - integer<br>
    topology    - full | 3D | rand2D | sphere | line | imp2D<br>
    algorithm   - gossip | push-sum<br>

	Eg:  <br>
	\DOS\Projects\proj2 <br>
	\DOS\Projects\proj2> mix escript.build <br>
	\DOS\Projects\proj1> ./proj2 300 rand2D push-sum <br>
	
	O/P: <br>
    Convergence Achieved in = 14657 ms
	
***

#### Bonus Instructions:

usage: ./proj2 num_actors topology algorithm num_fail_nodes

***

##### Note: 
To see when and which actors have terminated, uncomment line 39 in lib/proj2/gossip.ex, and line 60 in lib/proj2/pushsum.ex.

***

#### What is working:

All topologies are working for both algorithms. 

***

#### Largest Network:

##### Gossip

All topologies we tested could handle at least 10,000 nodes. The algorithm will work with larger networks, but will take much longer.

##### Push-Sum

Full: 5,000<br>
3D: 1,500<br>
Rand2D: 600<br>
Sphere: 600<br>
Line: 300<br>
ImperfectLine: 3,000



