//! This program will take in a member's internal force and length and will output:
//! - The best compatible HSS shape
//! - The member's dead load
//! - The maximum internal force the shape can withstand
//! - The stress on the member
//! - The strain of the member
//! 
//! The programming language of this program is Rust.

use std::{
    error::Error,
    f64::consts::PI,
    io::{Write, stdin, stdout},
    str::FromStr,
};

// This function will prompt the user to enter a value.
fn input<F: FromStr>(prompt: &str) -> Result<F, Box<dyn Error>>
where
    F::Err: Error + 'static,
{
    print!("{}", prompt);
    stdout().flush()?;
    let mut string = String::new();
    stdin().read_line(&mut string)?;
    return Ok(F::from_str(string.trim())?);
}

type HssShape = [f64; 6];
// Our big table of HSS shapes found in Appendix A of the Project Submission 2 Description (list of 6 values: [d, b, t, dead load, area, r])
const HSS_SHAPES: [HssShape; 29] = [
    [51., 51., 6.4, 0.079, 1030., 17.6],
    [76., 51., 6.5, 0.104, 1350., 26.1],
    [76., 51., 8.0, 0.155, 1600., 25.1],
    [89., 64., 8.0, 0.155, 2010., 30.5],
    [102., 102., 6.4, 0.178, 2320., 38.4],
    [102., 76., 8.0, 0.186, 2410., 35.8],
    [102., 76., 9.5, 0.215, 2790., 35.0],
    [127., 64., 9.5, 0.234, 3030., 41.7],
    [127., 76., 9.5, 0.252, 3280., 43.2],
    [152., 102., 8.0, 0.279, 3620., 54.8],
    [152., 102., 9.5, 0.327, 4240., 54.0],
    [152., 102., 11., 0.373, 4840., 53.1],
    [203., 102., 9.5, 0.401, 5210., 70.3],
    [203., 102., 11., 0.460, 5870., 69.3],
    [203., 102., 13., 0.514, 6680., 68.4],
    [203., 152., 9.5, 0.476, 6180., 75.1],
    [203., 152., 11., 0.547, 7100., 74.2],
    [254., 254., 8.0, 0.590, 7660., 99.9],
    [254., 254., 9.5, 0.699, 9090., 99.1],
    [254., 254., 13., 0.912, 11800., 97.6],
    [203., 152., 13., 0.614, 7970., 73.4],
    [254., 152., 11., 0.634, 8230., 91.0],
    [254., 152., 13., 0.713, 9260., 90.1],
    [305., 305., 8.0, 0.714, 9280., 121.],
    [305., 203., 9.5, 0.699, 9090., 113.],
    [305., 203., 11., 0.808, 10500., 112.],
    [305., 203., 13., 0.912, 11800., 111.],
    [305., 305., 11., 0.982, 12800., 119.],
    [305., 305., 13., 1.11, 14400., 118.],
];

// Computes the tensile resistance for a given HSS shape.
fn tensile_resistance(shape: HssShape) -> f64 {
    return 0.9 * shape[4] * 370.0 / 1000.0;
}
// Computes the tensile resistance for a given HSS shape and length.
fn compressive_resistance(shape: HssShape, length: f64) -> f64 {
    let sigma_e = (PI.powi(2) * 200_000.0) / (1.0 * length / shape[5]).powi(2);
    let lambda = (370.0 / sigma_e).sqrt();
    let f = 1.0 / (1.0 + lambda.powf(2.0 * 1.34)).powf(1.0 / 1.34);
    return 0.9 * f * shape[4] * 370.0 / 1000.0;
}
// Computes the tensile resistance for a given HSS shape and length.
// This version prints the intermediate calculation results.
fn compressive_resistance_debug(shape: HssShape, length: f64) -> f64 {
    let sigma_e = (PI.powi(2) * 200_000.0) / (1.0 * length / shape[5]).powi(2);
    println!("sigma_e: {sigma_e} MPa");
    let lambda = (370.0 / sigma_e).sqrt();
    println!("lambda: {lambda}");
    let f = 1.0 / (1.0 + lambda.powf(2.0 * 1.34)).powf(1.0 / 1.34);
    println!("f: {f}");
    return 0.9 * f * shape[4] * 370.0 / 1000.0;
}

// Our code starts here.
fn main() -> Result<(), Box<dyn Error>> {
    loop {
        // Use our input function to prompt the user for the internal tension or compression, as well as the length.
        let tension = input::<f64>("Tension (negative for compression): ")?;
        let length = input::<f64>("Length (m): ")?;

        // This computes the resistances of all HSS shapes with the given length (tensile resistance if the given force is greater than 0, otherwise compressive resistance).
        let candidates = if tension > 0.0 {
            HSS_SHAPES.map(tensile_resistance)
        } else {
            HSS_SHAPES.map(|shape| compressive_resistance(shape, length * 1000.0))
        };

        // We take the absolute of the tension/compression to yield the internal force (as the corresponding resistance has just been computed).
        let internal_force = tension.abs();

        // This iteration composition expression simply filters out all resistances that are less than the internal force, then selects the lightest member type.
        // The program will catch the edge case where *no* HSS shape is suitable.
        let (resistance, chosen_shape) = candidates
            .iter()
            .enumerate()
            .filter(|(_, resistance)| **resistance >= internal_force) // Filter out unsuitable resistances
            .fold((0.0, Option::<usize>::None), |(current_resistance, current_shape_index), (new_shape_index, new_resistance)| {
                // A shape's third index is it's dead load. This `if` statement is performed for all candidates and will select the lightest member.
                if current_shape_index.is_none() || HSS_SHAPES[new_shape_index][3] < HSS_SHAPES[current_shape_index.unwrap()][3] {
                    (*new_resistance, Some(new_shape_index))
                } else {
                    (current_resistance, current_shape_index)
                }
            });

        // This block will run if we have chosen a valid HSS shape.
        if let Some(shape) = chosen_shape {
            let shape = HSS_SHAPES[shape];
            println!("=========================================");
            // Display the most suitable shape, dead load, and maximum internal force.
            println!(
                "Best compatible shape: HSS {} X {} X {}\nDead load: {} kN\nMaximum internal force: {} kN",
                shape[0],
                shape[1],
                shape[2],
                shape[3] * length,
                resistance
            );
            let stress = (internal_force * 1000.0) / shape[4];
            let strain = stress * (length * 1000.0) / 200_000.0;
            // Display stress and strain.
            println!("Stress: {stress} MPa\nStrain: {strain} mm");
            // Display parameters for compressive resistance
            if tension < 0.0 {
                println!("--- Compressive resistance parameters ---");
                compressive_resistance_debug(shape, length * 1000.0);
            }
            println!("-----------------------------------------");
            // Prints information for copying + pasting into a text box in an engineering drawing.
            println!(
                "{} X {} X {}\n{:.3}kN",
                shape[0],
                shape[1],
                shape[2],
                shape[3] * length,
            );
            println!("=========================================");
        // This block will run if the internal force is too high for any of our HSS shapes.
        } else {
            println!("Unable to find a compatible HSS shape!");
        }
    }
}
