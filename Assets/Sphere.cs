using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Sphere : MonoBehaviour
{
    private new Rigidbody rigidbody;

    public float speed = 10;

    void Start ()
    {
        rigidbody = GetComponent<Rigidbody>();
    }
    void FixedUpdate ()
    {
        float x = Input.GetAxis("Horizontal");
        float z = Input.GetAxis("Vertical");

        rigidbody.AddForce(x * speed, 0, z * speed);
    }
}
