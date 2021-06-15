<?php
//Fonction de sécurisation des entrées utilisateurs
function securize($p) {
    $v = htmlspecialchars($p); //Convertir les caractères spéciaux
    $v = trim($v); //Supprimer les espaces dans la requête
    $v = rtrim($v); //Supprimer les espaces à la fin de la requête
    $v = strtolower($v); //Tout mettre en minuscule
    $v = strip_tags($v); //Supprimer les balises html dans la requête
    $v = stripslashes($v); //Supprimer les slash dans la requête
    $v = stripcslashes($v); //Supprimer les backslash dans la requête
    return $v;
}

//Fonction de requête 
function request() {
	global $tool, $term;
	$file = "results/$term.html";
    shell_exec("echo tools.sh $tool $term > pipe/pipe");
	//echo "<script>self.location='loader.html';</script>";
	//header("Location: loader.html");
	while (!file_exists("$file")) {
		clearstatcache();
	}
	//echo "<script>self.location='$file';</script>";
	header("Location: $file");
	die();
}

//Choix de l'outil
if (isset($_POST["search"])) {
	$term = securize($_POST['search']);
	if (!empty($term)) {
		if ($_POST["tool"] == "ghunt") {
			$tool = "a";
			request();
        } elseif ($_POST["tool"] == "holehe") {
			$tool = "b";
			request();
        } elseif ($_POST["tool"] == "sherlock") {
			$tool = "c";
			request();
        } elseif ($_POST["tool"] == "profil3r") {
			$tool = "d";
			request();
        } elseif ($_POST["tool"] == "phoneinfoga") {
			$tool = "e";
			request();
		} else {
			echo 'Il faut selectionner au moins un outil';
			die();			
		}
	} else {
		echo 'La nature a horreur du vide, entrez un terme de recherche';
		die();
	}
}
?>

<!-- Formulaire HTML -->
<!doctype html>
<html lang="fr">

<head>
	<!-- Required meta tags -->
	<meta charset="utf-8">
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<!-- Title -->
	<title>OSINT Facilitateur</title>
	<!-- Links -->
	<link rel="stylesheet" href="ressources/index.css">
</head>

<body>
	<h1 style="color:#0f500c"><a href="index.php" style="text-decoration: none">OSINT Facilitateur</a></h1>
	<form action="/" method="POST" target="_blank">
		<fieldset>
			<legend>Recherchez un mail, un téléphone ou un pseudo...</legend>
			<input type="search" placeholder="mail, téléphone ou pseudo..." name="search">
			<br>
			<hr/>
			<p> Sur quel outil souhaitez-vous lancer votre recherche? (un seul a la fois...) <i>Soyez cohérents... ne cherchez pas un téléphone sur un outil dédié aux mails... Et inversement </i></p>
				<div class="fields">
				<fieldset>
					<legend>Email</legend>
					<input type="radio" name="tool" value="ghunt">
					<label for="ghunt"><b><div class="tooltip">Ghunt<span class="tooltiptext">Informations d'un compte google</span></div></b></label>
					<br>
					<input type="radio" name="tool" value="holehe">
					<label for="holehe"><b><div class="tooltip">Holehe<span class="tooltiptext">Sites sur lesquels un email est inscrit</span></div></b></label>
				</fieldset>
				<fieldset>
					<legend>Pseudo</legend>
					<input type="radio" name="tool" value="sherlock">
					<label for="sherlock"><b><div class="tooltip">Sherlock<span class="tooltiptext">Sites sur lesquels un nom d'utilisateur est inscrit (prend du temps...)</span></div></b></label>
					<br>
					<input type="radio" name="tool" value="profil3r">
					<label for="profil3r"><b><div class="tooltip">Profil3r<span class="tooltiptext">Réseaux sociaux sur lesquels un nom d'utilisateur est inscrit</span></div></b></label>
				</fieldset>
				<fieldset>
					<legend>Téléphone</legend>
					<input type="radio" name="tool" value="phoneinfoga">
					<label for="phoneinfoga"><b><div class="tooltip">PhoneInfoGa<span class="tooltiptext">Informations sur un numéro de téléphone</span></div></b></label>
				</fieldset>
				</div>
				<p> sources des outils: 
				<a href="https://github.com/mxrch/GHunt" target="_blank">GHunt</a>, 
				<a href="https://github.com/megadose/holehe" target="_blank">Holehe</a>, 
				<a href="https://github.com/sherlock-project/sherlock" target="_blank">Sherlock</a>, 
				<a href="https://github.com/Rog3rSm1th/Profil3r" target="_blank">Profil3r</a>, 
				<a href="https://github.com/sundowndev/phoneinfoga" target="_blank">PhoneInfoGa</a></p>
			<hr/>
			<button type="submit" name="submit" id="submit">Check the truth</button>
		</fieldset>
	</form>
	</body>
</html>